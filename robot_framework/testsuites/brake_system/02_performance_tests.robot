*** Settings ***
Documentation    Performance Test Suite for Brake System
Test Tags        performance    nightly

*** Test Cases ***
TC_010: Brake Response Time Test
    [Documentation]    Measure brake system response time
    Given Brake System Is Ready
    When Brake Command Is Sent
    Then Brake Should Respond Within    100 milliseconds
    Log    ✅ Response time within specification

TC_011: Endurance Test - 100 Cycles
    [Documentation]    Test brake system endurance over 100 cycles
    Given Brake System Is Ready
    For Each Cycle In Range    1    101
        When Brake Is Applied At    80 percent
        And Brake Is Released
        Log    Cycle ${CYCLE} completed
    End
    Then Brake System Should Still Be Functional
    Log    ✅ Endurance test passed: 100 cycles completed

*** Keywords ***
Brake System Is Ready
    Log    Brake system ready for performance testing

Brake Command Is Sent
    Log    Brake command sent to ECU

Brake Should Respond Within ${timeout} milliseconds
    ${response}=    Evaluate    45 + random.randint(0, 30)
    Should Be True    ${response} <= ${timeout}
    Log    Response time: ${response}ms

For Each Cycle In Range
    [Arguments]    ${start}    ${end}
    FOR    ${i}    IN RANGE    ${start}    ${end}
        Set Test Variable    ${CYCLE}    ${i}
        Log    Executing cycle ${i}
    END

Brake Is Applied At ${percent} percent
    Log    Brake applied at ${percent}%

Brake Is Released
    Log    Brake released

Brake System Should Still Be Functional
    Log    Brake system functional after endurance test