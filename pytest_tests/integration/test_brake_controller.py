"""
Integration tests for Brake Controller
Following company testing standards and ISO 26262 guidelines
"""
import pytest
import time
import asyncio
import logging
from typing import Dict, List, Any
from dataclasses import dataclass
import numpy as np

logger = logging.getLogger(__name__)

# Test markers for categorization
pytestmark = [
    pytest.mark.integration,
    pytest.mark.brake_controller,
    pytest.mark.regression
]


@dataclass
class BrakeTestScenario:
    """Test scenario data structure"""
    name: str
    initial_speed: float  # km/h
    brake_pressure: float  # percent
    road_friction: float
    expected_deceleration: float  # m/s²
    max_stopping_distance: float  # meters
    abs_expected: bool
    stability_expected: bool


class TestBrakeControllerIntegration:
    """
    Comprehensive integration tests for brake controller
    Covers all safety-critical aspects per ISO 26262 ASIL-D
    """

    @pytest.fixture(autouse=True)
    async def setup_teardown(self, hil_rig, can_interface):
        """Setup and teardown for each test"""
        self.hil = hil_rig
        self.can = can_interface

        # Initialize systems
        await self.hil.power_on()
        await self.hil.initialize_system()
        await self.can.initialize(bitrate=500000)

        # Clear any existing faults
        await self.hil.clear_faults()

        # Start data recording
        self.data_recorder = DataRecorder()
        await self.data_recorder.start()

        yield

        # Teardown
        await self.data_recorder.stop()
        await self.can.disconnect()
        await self.hil.power_off()

        # Save test data
        self.data_recorder.save(f"test_data_{self.test_name}.json")

    @pytest.mark.smoke
    @pytest.mark.asyncio
    async def test_initialization_sequence(self):
        """Test proper initialization of brake controller"""
        # Verify CAN communication
        assert await self.can.is_connected(), "CAN bus not connected"

        # Verify ECU responds
        response = await self.hil.send_diagnostic_request(
            service="read_data",
            identifier="software_version"
        )
        assert response is not None, "ECU not responding"
        assert "version" in response, "Invalid response format"

        # Verify sensors are online
        sensors = await self.hil.get_sensor_status()
        assert all(sensors.values()), "Some sensors offline"

        logger.info("Brake controller initialized successfully")

    @pytest.mark.smoke
    @pytest.mark.parametrize("scenario", [
        BrakeTestScenario(
            name="normal_dry_braking",
            initial_speed=50,
            brake_pressure=50,
            road_friction=0.8,
            expected_deceleration=5.0,
            max_stopping_distance=20,
            abs_expected=False,
            stability_expected=True
        ),
        BrakeTestScenario(
            name="emergency_dry_braking",
            initial_speed=100,
            brake_pressure=100,
            road_friction=0.8,
            expected_deceleration=9.5,
            max_stopping_distance=45,
            abs_expected=False,
            stability_expected=True
        ),
        BrakeTestScenario(
            name="emergency_wet_braking",
            initial_speed=80,
            brake_pressure=100,
            road_friction=0.4,
            expected_deceleration=6.5,
            max_stopping_distance=55,
            abs_expected=True,
            stability_expected=True
        ),
        BrakeTestScenario(
            name="ice_braking",
            initial_speed=40,
            brake_pressure=100,
            road_friction=0.1,
            expected_deceleration=2.5,
            max_stopping_distance=45,
            abs_expected=True,
            stability_expected=True
        )
    ])
    @pytest.mark.asyncio
    async def test_braking_scenarios(self, scenario):
        """Test various braking scenarios"""
        logger.info(f"Testing scenario: {scenario.name}")

        # Setup scenario
        await self.hil.set_vehicle_speed(scenario.initial_speed)
        await self.hil.set_road_friction(scenario.road_friction)

        # Start recording
        await self.data_recorder.start_recording(
            signals=['speed', 'pressure', 'abs_active', 'yaw_rate'],
            duration=10,
            rate=100  # 100 Hz
        )

        # Apply brakes
        await self.hil.set_brake_pressure(scenario.brake_pressure)

        # Wait for stop
        timeout = scenario.max_stopping_distance / (scenario.initial_speed / 3.6) * 2
        await self.hil.wait_for_stop(timeout=timeout)

        # Stop recording
        data = await self.data_recorder.stop_recording()

        # Analyze results
        analysis = self._analyze_braking_data(data, scenario)

        # Assertions
        assert analysis['stopping_distance'] <= scenario.max_stopping_distance, \
            f"Stopping distance {analysis['stopping_distance']:.1f}m exceeds {scenario.max_stopping_distance}m"

        assert abs(analysis['avg_deceleration'] - scenario.expected_deceleration) <= 0.5, \
            f"Deceleration {analysis['avg_deceleration']:.2f}m/s² outside expected {scenario.expected_deceleration}±0.5"

        if scenario.abs_expected:
            assert analysis['abs_activated'], "ABS should have activated but didn't"
            assert analysis['abs_cycles'] >= 3, f"Too few ABS cycles: {analysis['abs_cycles']}"
        else:
            assert not analysis['abs_activated'], "ABS activated when not expected"

        assert analysis['stable'] == scenario.stability_expected, \
            f"Stability: expected {scenario.stability_expected}, got {analysis['stable']}"

        logger.info(f"✅ Scenario {scenario.name} passed")

    @pytest.mark.performance
    @pytest.mark.asyncio
    async def test_response_time(self):
        """Test brake system response time"""
        # Measure initial response
        start_time = time.time()
        await self.hil.set_brake_pressure(50)

        # Wait for pressure build
        pressure_time = await self.hil.wait_for_pressure(
            threshold=10,
            timeout=1.0
        )

        response_time = (time.time() - start_time) * 1000
        assert response_time < 100, f"Response time {response_time:.1f}ms > 100ms"

        # Measure pressure rise time (10% to 90%)
        rise_time = await self.hil.measure_pressure_rise_time(
            start_percent=10,
            end_percent=90
        )
        assert rise_time < 80, f"Rise time {rise_time:.1f}ms > 80ms"

        logger.info(f"Response time: {response_time:.1f}ms, Rise time: {rise_time:.1f}ms")

    @pytest.mark.safety
    @pytest.mark.parametrize("failure_type,expected_mode", [
        ("sensor_failure", "degraded"),
        ("communication_loss", "fail_safe"),
        ("power_interrupt", "recovery"),
        ("actuator_stuck", "fault")
    ])
    @pytest.mark.asyncio
    async def test_failure_modes(self, failure_type, expected_mode):
        """Test system behavior in failure modes"""
        logger.info(f"Testing failure mode: {failure_type}")

        # Inject failure
        await self.hil.inject_failure(failure_type)

        # Check system response
        mode = await self.hil.get_system_mode()
        assert mode == expected_mode, f"Wrong mode: expected {expected_mode}, got {mode}"

        # Check warning indicators
        warnings = await self.hil.get_warning_status()
        assert warnings.get(failure_type, False), f"Warning not set for {failure_type}"

        # Verify safe behavior
        if failure_type == "sensor_failure":
            # Should still have braking capability
            await self.hil.set_brake_pressure(50)
            pressure = await self.hil.get_brake_pressure()
            assert pressure > 0, "No braking after sensor failure"

        elif failure_type == "communication_loss":
            # Should be in fail-safe with full braking
            pressure = await self.hil.get_brake_pressure()
            assert pressure > 30, "Insufficient fail-safe braking"

        # Clear failure
        await self.hil.clear_failure()

        # Verify recovery
        mode = await self.hil.get_system_mode()
        assert mode == "normal", f"Failed to recover: mode={mode}"

        logger.info(f"✅ Failure mode {failure_type} handled correctly")

    @pytest.mark.nightly
    @pytest.mark.performance
    @pytest.mark.asyncio
    async def test_endurance_braking(self):
        """Endurance test - 1000 brake cycles"""
        cycles = 1000
        failures = []
        performance_data = []

        logger.info(f"Starting endurance test: {cycles} cycles")

        for cycle in range(cycles):
            try:
                # Random test parameters
                speed = np.random.uniform(30, 100)
                pressure = np.random.uniform(30, 100)

                # Perform brake cycle
                start_time = time.time()

                await self.hil.set_vehicle_speed(speed)
                await self.hil.set_brake_pressure(pressure)
                await self.hil.wait_for_stop(timeout=10)

                cycle_time = time.time() - start_time

                # Record performance
                performance_data.append({
                    'cycle': cycle,
                    'speed': speed,
                    'pressure': pressure,
                    'time': cycle_time
                })

                # Cool down period
                await asyncio.sleep(2)

                if cycle % 100 == 0:
                    logger.info(f"Progress: {cycle}/{cycles} cycles")

            except Exception as e:
                failures.append({
                    'cycle': cycle,
                    'error': str(e),
                    'speed': speed,
                    'pressure': pressure
                })

                # Attempt recovery
                await self.hil.reset_system()
                await asyncio.sleep(5)

        # Analysis
        assert len(failures) == 0, f"Endurance test failed: {failures}"

        # Calculate statistics
        avg_time = np.mean([p['time'] for p in performance_data])
        std_time = np.std([p['time'] for p in performance_data])

        logger.info(f"""
        Endurance Test Results:
        - Total cycles: {cycles}
        - Average cycle time: {avg_time:.2f}s
        - Std deviation: {std_time:.2f}s
        - Min time: {min(p['time'] for p in performance_data):.2f}s
        - Max time: {max(p['time'] for p in performance_data):.2f}s
        """)

        # Verify no degradation
        assert avg_time < 15, f"Average cycle time too high: {avg_time:.2f}s"

    def _analyze_braking_data(self, data: Dict, scenario: BrakeTestScenario) -> Dict:
        """Analyze braking data for metrics"""
        import numpy as np

        times = data['timestamps']
        speeds = np.array(data['vehicle_speed']) / 3.6  # to m/s
        pressures = data['brake_pressure']
        abs_active = data.get('abs_active', [False] * len(times))

        # Stopping distance
        time_diffs = np.diff(times)
        distances = speeds[:-1] * time_diffs
        stopping_distance = np.sum(distances)

        # Deceleration
        deceleration = -np.diff(speeds) / time_diffs
        avg_deceleration = np.mean(deceleration)

        # ABS analysis
        abs_activated = any(abs_active)
        abs_cycles = self._count_abs_cycles(abs_active)

        # Stability
        yaw_rate = data.get('yaw_rate', [0] * len(times))
        max_yaw = max(abs(np.array(yaw_rate)))
        stable = max_yaw < 5  # deg/s

        return {
            'stopping_distance': stopping_distance,
            'avg_deceleration': avg_deceleration,
            'abs_activated': abs_activated,
            'abs_cycles': abs_cycles,
            'stable': stable,
            'max_yaw': max_yaw
        }

    def _count_abs_cycles(self, abs_active: List[bool]) -> int:
        """Count ABS cycles from binary signal"""
        cycles = 0
        in_cycle = False

        for active in abs_active:
            if active and not in_cycle:
                cycles += 1
                in_cycle = True
            elif not active:
                in_cycle = False

        return cycles


class DataRecorder:
    """Test data recorder"""

    def __init__(self):
        self.recording = False
        self.data = []

    async def start(self):
        self.recording = True
        logger.info("Data recorder started")

    async def start_recording(self, signals: List[str], duration: float, rate: int):
        self.signals = signals
        self.recording = True
        self.data = []
        logger.info(f"Recording {signals} for {duration}s at {rate}Hz")

    async def stop_recording(self):
        self.recording = False
        logger.info("Recording stopped")
        return {'timestamps': [1, 2, 3], 'vehicle_speed': [50, 40, 30]}  # Mock data

    async def stop(self):
        self.recording = False
        logger.info("Data recorder stopped")

    def save(self, filename: str):
        logger.info(f"Saving data to {filename}")
        # Mock save