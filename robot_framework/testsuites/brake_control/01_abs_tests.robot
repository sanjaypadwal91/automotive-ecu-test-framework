*** Settings ***
Documentation    ABS (Anti-lock Braking System) Test Suite
...              Validates ABS functionality according to ISO 26262
...              Reference: VOLVO-ABS-TS-001

Resource         ../../resources/common/can_keywords.robot
Resource         ../../resources/common/diagnostic_keywords.robot
Resource         ../../resources/common/vehicle_simulation.robot

Suite Setup      Setup ABS Test Environment
Suite Teardown   Teardown ABS Test Environment
Test Setup       Initialize Test Case
Test Teardown    Analyze Test Results

Library          Collections
Library          DateTime
Library          OperatingSystem

*** Variables ***
# CAN Signals
${ABS_ACTIVE_SIGNAL}        0x1A3
${WHEEL_SPEED_FR}           0x220
${WHEEL_SPEED_FL}           0x221
${WHEEL_SPEED_RR}           0x222
${WHEEL_SPEED_RL}           0x223
${BRAKE_PRESSURE}           0x1A0
${VEHICLE_SPEED}            0x120
${YAW_RATE}                 0x320

# Test Parameters
${ABS_ACTIVATION_THRESHOLD}    100    # ms
${ABS_DEACTIVATION_THRESHOLD}  50     # ms
${MAX_YAW_RATE}                3      # deg/s

*** Test Cases ***
TC_ABS_001: Verify ABS Activation on Low Friction Surface
    [Documentation]    Test ABS activates when braking on ice (μ=0.1)
    ...                Expected: ABS activates within 100ms, wheels don't lock
    [Tags]    smoke    safety    ISO26262-ASIL-D

    [Setup]    Setup Low Friction Test
    Given Vehicle Speed Is    80 km/h
    And Road Friction Is       0.1
    When Driver Applies Full Brake
    Then ABS Should Activate Within    ${ABS_ACTIVATION_THRESHOLD} ms
    And All Wheels Should Rotate Above    5 km/h
    And Vehicle Should Stop Within    50 meters
    [Teardown]    Teardown Low Friction Test

TC_ABS_002: Verify ABS on Split-Mu Surface
    [Documentation]    Test ABS behavior on split friction
    ...                Left wheels on ice (μ=0.1), Right on dry asphalt (μ=0.8)
    [Tags]    regression    stability    ISO26262-ASIL-C

    Given Vehicle Speed Is    60 km/h
    And Left Wheels Friction Is    0.1
    And Right Wheels Friction Is    0.8
    When Driver Applies Full Brake
    Then Vehicle Should Maintain Stability
    And Yaw Rate Should Be Below    ${MAX_YAW_RATE} deg/s
    And ABS Should Activate On Both Axles

TC_ABS_003: Verify ABS Deactivation When Brake Released
    [Documentation]    Test ABS deactivates properly when brake is released
    [Tags]    regression    safety

    Given ABS Is Active
    When Driver Releases Brake
    Then ABS Should Deactivate Within    ${ABS_DEACTIVATION_THRESHOLD} ms
    And Brake Pressure Should Return To Zero

TC_ABS_004: Verify ABS Failure Mode
    [Documentation]    Test system behavior during ABS failure
    [Tags]    safety    fault-injection    ISO26262-ASIL-D

    Given ABS Module Fault Is Injected
    When Driver Applies Brakes
    Then Brake Warning Light Should Illuminate
    And Base Braking Should Remain Functional
    And DTC "C1234" Should Be Stored

TC_ABS_005: ABS Performance at High Speed
    [Documentation]    Test ABS performance at highway speeds
    [Tags]    performance    nightly

    Given Vehicle Speed Is    120 km/h
    And Road Friction Is       0.4    # Wet road
    When Driver Applies Full Brake
    Then ABS Should Activate Within    ${ABS_ACTIVATION_THRESHOLD} ms
    And Stopping Distance Should Be Less Than    70 meters
    And Vehicle Should Not Deviate More Than    0.5 meters from center

*** Keywords ***
Setup ABS Test Environment
    [Documentation]    Initialize all test systems
    Initialize CAN Communication    interface=can0    bitrate=500000
    Initialize Diagnostic Session    session_type=extended
    Load Vehicle Model    model=volvo_fh16_2025
    Set Test Environment    type=hil    rig_id=brake-test-01
    Clear All DTCs
    Log    ABS Test Suite Initialized    level=INFO

Teardown ABS Test Environment
    [Documentation]    Clean up after all tests
    Collect Diagnostic Data
    Save CAN Trace    filename=abs_tests.asc
    Disconnect HIL Rig
    Close CAN Connection
    Log    ABS Test Suite Completed    level=INFO

Initialize Test Case
    [Documentation]    Reset state before each test
    Reset Vehicle State
    Start CAN Recording    duration=${TEST_DURATION}
    Log    Starting test: ${TEST NAME}    level=INFO

Analyze Test Results
    [Documentation]    Collect and analyze test data
    ${dtcs}=    Read DTC Information
    Run Keyword If    ${dtcs}    Log    Active DTCs: ${dtcs}    level=WARN
    ${can_trace}=    Stop CAN Recording
    Save File    ${can_trace}    ${TEST_REPORT_DIR}/can_trace_${TEST NAME}.asc

    # Check for regressions
    ${regression}=    Check Regression    test_name=${TEST NAME}
    Run Keyword If    ${regression}    Log    Regression detected!    level=ERROR

Vehicle Speed Is ${speed} km/h
    [Documentation]    Set vehicle speed in simulator
    Set Vehicle Speed    speed=${speed}
    ${actual}=    Get Vehicle Speed
    Should Be Equal As Numbers    ${actual}    ${speed}    tolerance=1
    Log    Vehicle speed set to ${speed} km/h    level=DEBUG

Road Friction Is ${mu}
    [Documentation]    Set road friction coefficient
    Set Road Friction    coefficient=${mu}
    ${actual}=    Get Road Friction
    Should Be Equal As Numbers    ${actual}    ${mu}    tolerance=0.05
    Log    Road friction set to ${mu}    level=DEBUG

Left Wheels Friction Is ${mu}
    [Documentation]    Set left side friction
    Set Wheel Friction    wheels=left    coefficient=${mu}
    Log    Left wheel friction set to ${mu}    level=DEBUG

Right Wheels Friction Is ${mu}
    [Documentation]    Set right side friction
    Set Wheel Friction    wheels=right    coefficient=${mu}
    Log    Right wheel friction set to ${mu}    level=DEBUG

Driver Applies Full Brake
    [Documentation]    Simulate full brake pedal application
    Set Pedal Position    position=100    ramp_time=0.1
    ${pressure}=    Wait For Signal    id=${BRAKE_PRESSURE}    timeout=2
    Should Be True    ${pressure} > 50    Brake pressure too low
    Log    Full brake applied, pressure: ${pressure} bar    level=INFO

Driver Releases Brake
    [Documentation]    Release brake pedal
    Set Pedal Position    position=0    ramp_time=0.05
    ${pressure}=    Wait For Signal    id=${BRAKE_PRESSURE}    timeout=1    condition=<5
    Should Be True    ${pressure} < 5    Brake pressure not released
    Log    Brake released    level=DEBUG

ABS Should Activate Within ${timeout} ms
    [Documentation]    Verify ABS activates within specified time
    ${start_time}=    Get Current Timestamp
    ${active}=    Wait For Signal    id=${ABS_ACTIVE_SIGNAL}    value=1    timeout=${timeout}
    ${duration}=    Evaluate    (Get Current Timestamp - ${start_time}) * 1000
    Should Be True    ${active}    ABS did not activate
    Should Be True    ${duration} <= ${timeout}
    ...    ABS activation took ${duration:.0f}ms, expected ≤ ${timeout}ms
    Log    ABS activated in ${duration:.0f}ms    level=INFO

ABS Should Deactivate Within ${timeout} ms
    [Documentation]    Verify ABS deactivates within specified time
    ${start_time}=    Get Current Timestamp
    ${inactive}=    Wait For Signal    id=${ABS_ACTIVE_SIGNAL}    value=0    timeout=${timeout}
    ${duration}=    Evaluate    (Get Current Timestamp - ${start_time}) * 1000
    Should Be True    ${inactive}    ABS did not deactivate
    Should Be True    ${duration} <= ${timeout}
    ...    ABS deactivation took ${duration:.0f}ms, expected ≤ ${timeout}ms
    Log    ABS deactivated in ${duration:.0f}ms    level=INFO

All Wheels Should Rotate Above ${min_speed} km/h
    [Documentation]    Verify wheels aren't locked during ABS activation
    ${wheel_speeds}=    Create List
    FOR    ${wheel_id}    IN    ${WHEEL_SPEED_FR}    ${WHEEL_SPEED_FL}    ${WHEEL_SPEED_RR}    ${WHEEL_SPEED_RL}
        ${speed}=    Get Signal    id=${wheel_id}
        Append To List    ${wheel_speeds}    ${speed}
        Should Be True    ${speed} > ${min_speed}
        ...    Wheel ${wheel_id} stopped (${speed:.1f} km/h)
    END
    Log    Wheel speeds: ${wheel_speeds}    level=DEBUG

Vehicle Should Stop Within ${max_distance} meters
    [Documentation]    Verify stopping distance meets requirements
    ${distance}=    Get Stopping Distance
    Should Be True    ${distance} <= ${max_distance}
    ...    Stopping distance ${distance:.1f}m exceeds ${max_distance}m
    Log    Stopping distance: ${distance:.1f}m    level=INFO

Vehicle Should Maintain Stability
    [Documentation]    Verify vehicle doesn't spin or swerve
    ${yaw_rate}=    Get Signal    id=${YAW_RATE}
    Should Be True    abs(${yaw_rate}) < ${MAX_YAW_RATE}
    ...    Yaw rate ${yaw_rate:.1f} deg/s exceeds limit
    ${lateral_accel}=    Get Lateral Acceleration
    Should Be True    abs(${lateral_accel}) < 5
    ...    Lateral acceleration ${lateral_accel:.1f} m/s² excessive

Yaw Rate Should Be Below ${limit} deg/s
    [Documentation]    Specific yaw rate check
    ${yaw_rate}=    Get Signal    id=${YAW_RATE}
    Should Be True    abs(${yaw_rate}) < ${limit}
    ...    Yaw rate ${yaw_rate:.1f} deg/s exceeds ${limit} deg/s

ABS Should Activate On Both Axles
    [Documentation]    Verify ABS active on front and rear
    ${front_active}=    Get ABS Status    axle=front
    ${rear_active}=    Get ABS Status    axle=rear
    Should Be True    ${front_active} and ${rear_active}
    ...    ABS not active on both axles (front:${front_active}, rear:${rear_active})

Brake Pressure Should Return To Zero
    [Documentation]    Verify brake pressure returns to 0
    ${pressure}=    Get Signal    id=${BRAKE_PRESSURE}
    Should Be True    ${pressure} < 2
    ...    Residual pressure: ${pressure:.1f} bar

ABS Module Fault Is Injected
    [Documentation]    Inject fault in ABS module
    Inject Fault    module=abs    fault_type=internal_error
    Log    ABS fault injected    level=WARN

Brake Warning Light Should Illuminate
    [Documentation]    Verify warning light is on
    ${warning}=    Get Warning Status    light=brake
    Should Be True    ${warning}
    ...    Brake warning light not illuminated

Base Braking Should Remain Functional
    [Documentation]    Verify mechanical braking works
    Apply Brake    pressure=50
    ${deceleration}=    Get Vehicle Deceleration
    Should Be True    ${deceleration} > 2
    ...    Base braking failed, deceleration: ${deceleration:.1f} m/s²
    Release Brake

DTC "${dtc_code}" Should Be Stored
    [Documentation]    Verify specific DTC is stored
    ${dtcs}=    Read DTC Information
    ${found}=    Evaluate    "${dtc_code}" in str(${dtcs})
    Should Be True    ${found}
    ...    DTC ${dtc_code} not found in stored DTCs: ${dtcs}

Stopping Distance Should Be Less Than ${max_distance} meters
    [Documentation]    Performance check for stopping distance
    ${distance}=    Get Stopping Distance
    Should Be True    ${distance} <= ${max_distance}
    ...    Stopping distance ${distance:.1f}m exceeds ${max_distance}m

Vehicle Should Not Deviate More Than ${max_deviation} meters from center
    [Documentation]    Check lateral deviation during braking
    ${deviation}=    Get Lateral Deviation
    Should Be True    abs(${deviation}) <= ${max_deviation}
    ...    Vehicle deviated ${deviation:.2f}m from center

ABS Is Active
    [Documentation]    Set ABS to active state for testing
    Set ABS State    state=active
    ${active}=    Get ABS Status
    Should Be True    ${active}
    Log    ABS set to active    level=INFO

Setup Low Friction Test
    [Documentation]    Special setup for low friction
    Set Temperature    value=-10    unit=C
    Set Surface Type    type=ice
    Set Tire Type    type=winter

Teardown Low Friction Test
    [Documentation]    Cleanup after low friction
    Reset Surface Conditions
    Reset Temperature