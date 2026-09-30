Feature: Sample Feature Specification
  As a user or client of the system
  I want to perform an action
  So that I achieve a clear business outcome

  Scenario: Successful operation with valid input
    Given the system is in an initialized state
    When the user submits valid data
    Then the system processes the request successfully
    And emits a success confirmation

  Scenario: Error handling with invalid input
    Given the system is in an initialized state
    When the user submits invalid or missing data
    Then the system rejects the operation with a validation error
    And leaves persistent state unaltered
