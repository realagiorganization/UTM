import os
import subprocess

from behave import given, when, then


@given("the LLM API key is available")
def step_llm_key_available(context):
    api_key = os.environ.get("OPENCODE_LLM_KEY", "").strip()
    assert api_key, "OPENCODE_LLM_KEY is not set"
    context.llm_key_length = len(api_key)


@when("the opencode CLI request runs inside tmux")
def step_run_opencode_tmux(context):
    script_path = os.path.join("scripts", "run_opencode_in_tmux.sh")
    result = subprocess.run([script_path], check=False, text=True, capture_output=True)
    context.opencode_result = result


@then("the request completes successfully")
def step_request_success(context):
    result = context.opencode_result
    assert result.returncode == 0, result.stderr
    assert "Local mock request succeeded" in result.stdout
