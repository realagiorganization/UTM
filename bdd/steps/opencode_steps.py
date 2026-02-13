import os
import subprocess

from behave import given, when, then


@given("the LLM API key is available")
def step_llm_key_available(context):
    api_key = os.environ.get("OPENCODE_LLM_KEY", "").strip()
    assert api_key, "OPENCODE_LLM_KEY is not set"
    context.llm_key_length = len(api_key)


@given("the opencode CLI is installed")
def step_install_opencode(context):
    install_script = os.path.join("scripts", "install_opencode_cli.sh")
    result = subprocess.run([install_script], check=True, text=True, capture_output=True)
    bin_dir = result.stdout.strip().splitlines()[-1]
    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"
    context.opencode_env = env


@when("the opencode CLI request runs inside tmux")
def step_run_opencode_tmux(context):
    script_path = os.path.join("scripts", "run_opencode_in_tmux.sh")
    env = getattr(context, "opencode_env", None)
    result = subprocess.run(
        [script_path],
        check=False,
        text=True,
        capture_output=True,
        env=env,
    )
    context.opencode_result = result


@then("the request completes successfully")
def step_request_success(context):
    result = context.opencode_result
    assert result.returncode == 0, result.stderr
    assert "Local mock request succeeded" in result.stdout
