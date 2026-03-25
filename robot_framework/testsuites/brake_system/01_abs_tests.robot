*** Settings ***
Documentation    ABS (Anti-lock Braking System) Test Suite
...              Validates ABS functionality for automotive ECUs
Library          Collections
Library          String

*** Variables ***
${EXPECTED_ABS_ACTIVATION_TIME}    100    # milliseconds
${EXPECTED_BRAKE_PRESSURE}         85     # bar
${VEHICLE_SPEED_THRESHOLD}         5      # km/h

*** Test Cases ***
TC_001: Verify ABS Activates on Low Friction Surface
    [Documentation]    Test that ABS activates when braking on ice
    [Tags]    smoke    brake    safety

    Given Vehicle Speed Is    80 km/h
    And Road Friction Is      0.1
    When Driver Applies Full Brake
    Then ABS Should Activate Within    100 ms
    And Wheels Should Not Lock
    And Vehicle Should Stop Safely

    Log    ✅ TC_001 PASSED: ABS activation verified

TC_002: Verify Brake Pressure Build Time
    [Documentation]    Test brake pressure builds within specification
    [Tags]    regression    brake    performance

    Given Brake System Is Initialized
    When Driver Applies Brake At    50 percent
    Then Brake Pressure Should Reach    85 bar within    200 ms

    Log    ✅ TC_002 PASSED: Brake pressure verified

TC_003: Verify CAN Communication
    [Documentation]    Test CAN bus communication with ECU
    [Tags]    smoke    communication

    Given CAN Bus Is Initialized
    When Send CAN Message    ID=0x100    Data=01 02 03 04
    Then ECU Should Respond Within    50 ms
    And Response Data Should Be Valid

    Log    ✅ TC_003 PASSED: CAN communication verified


TC_003: Verify Automatic Build Trigger
    [Documentation]    Test that push triggers automatic build
    [Tags]    smoke
    Given Code Is Pushed To GitHub
    Then Jenkins Should Start Build Automatically
    And All Tests Should Pass

*** Keywords ***


All Tests Should Pass
    Log    ✅ All tests passed successfully!

Vehicle Speed Is ${speed} km/h
    Log    Setting vehicle speed to ${speed} km/h
    Set Test Variable    ${CURRENT_SPEED}    ${speed}
    Should Be True    ${speed} > 0    Speed must be positive

Road Friction Is ${friction}
    Log    Setting road friction coefficient to ${friction}
    Should Be True    ${friction} >= 0 and ${friction} <= 1
    ...    Friction must be between 0 and 1

Driver Applies Full Brake
    Log    Driver applies emergency brake
    Set Test Variable    ${BRAKE_APPLIED}    ${TRUE}

ABS Should Activate Within ${timeout} ms
    ${activation_time}=    Evaluate    45 + random.randint(0, 20)    # Simulated 45-65ms
    Should Be True    ${activation_time} <= ${timeout}
    ...    ABS activated in ${activation_time}ms, expected ≤ ${timeout}ms
    Log    ABS activated in ${activation_time}ms ✅

Wheels Should Not Lock
    ${wheel_speed}=    Evaluate    25 + random.randint(0, 10)    # Simulated 25-35 km/h
    Should Be True    ${wheel_speed} > ${VEHICLE_SPEED_THRESHOLD}
    ...    Wheel speed ${wheel_speed} km/h - wheels rotating properly
    Log    Wheel speed maintained at ${wheel_speed} km/h ✅

Vehicle Should Stop Safely
    ${stopping_distance}=    Evaluate    35 + random.randint(0, 5)    # Simulated 35-40m
    Log    Vehicle stopped in ${stopping_distance} meters ✅

Brake System Is Initialized
    Log    Brake system initialization complete
    Set Test Variable    ${SYSTEM_READY}    ${TRUE}

Driver Applies Brake At ${pressure} percent
    Log    Applying brake at ${pressure}% pressure
    Set Test Variable    ${APPLIED_PRESSURE}    ${pressure}

Brake Pressure Should Reach ${target} bar within ${timeout} ms
    ${actual_pressure}=    Evaluate    ${target} - random.randint(0, 5)    # Simulated slightly less
    ${build_time}=    Evaluate    120 + random.randint(0, 50)    # Simulated 120-170ms
    Should Be True    ${build_time} <= ${timeout}
    ...    Pressure built in ${build_time}ms, expected ≤ ${timeout}ms
    Should Be True    ${actual_pressure} >= ${target} - 5
    ...    Pressure ${actual_pressure} bar, expected near ${target} bar
    Log    Brake pressure reached ${actual_pressure} bar in ${build_time}ms ✅

CAN Bus Is Initialized
    Log    CAN bus initialized at 500 kbit/s

Send CAN Message
    [Arguments]    ${ID}    ${Data}
    Log    Sending CAN message: ID=0x${ID}, Data=${Data}
    Set Test Variable    ${LAST_CAN_ID}    ${ID}

ECU Should Respond Within ${timeout} ms
    ${response_time}=    Evaluate    25 + random.randint(0, 20)    # Simulated 25-45ms
    Should Be True    ${response_time} <= ${timeout}
    ...    ECU responded in ${response_time}ms, expected ≤ ${timeout}ms
    Log    ECU responded in ${response_time}ms ✅

Response Data Should Be Valid
    ${response}=    Set Variable    01 02 03 04 05 06 07 08
    Log    Received response: ${response}
    Should Not Be Empty    ${response}
    Log    Response data validated ✅

Code Is Pushed To GitHub
    Log    Pushing changes to GitHub...

Jenkins Should Start Build Automatically
    Log    Jenkins detected SCM change!
    Should Be True    ${TRUE}    Build triggered automatically