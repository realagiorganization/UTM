Feature: UTM primary use cases
  As a user
  I want to configure and run virtual machines
  So that I can use multiple operating systems on my devices

  Scenario: Create and configure a new virtual machine
    Given the user has installed UTM
    And the user has access to a supported guest ISO
    When the user creates a new virtual machine profile
    And the user selects the target architecture
    And the user configures CPU, memory, and storage
    Then the virtual machine profile is saved
    And the virtual machine appears in the library

  Scenario: Run a virtual machine
    Given an existing virtual machine profile
    When the user starts the virtual machine
    Then the virtual machine boots successfully
    And the console or display is visible

  Scenario: Pause and resume a virtual machine
    Given a running virtual machine
    When the user pauses the virtual machine
    Then the virtual machine state is preserved
    When the user resumes the virtual machine
    Then the virtual machine continues execution

  Scenario: Import an existing virtual machine
    Given the user has an existing UTM VM package
    When the user imports the virtual machine into the library
    Then the virtual machine appears in the library
    And its configuration is accessible

  Scenario: Export and delete a virtual machine
    Given an existing virtual machine profile
    When the user exports the virtual machine package
    Then the exported package is created
    When the user deletes the virtual machine profile
    Then the virtual machine is removed from the library
