Feature: LLM CLI request via tmux
  As a developer
  I want to verify the opencode CLI can make a request using a secured key
  So that automated workflows can validate LLM connectivity

  Scenario: Run opencode CLI request in tmux
    Given the opencode CLI is installed
    Given the LLM API key is available
    When the opencode CLI request runs inside tmux
    Then the request completes successfully
