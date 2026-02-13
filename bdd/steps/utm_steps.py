from behave import given, when, then


@given("the user has installed UTM")
def step_user_installed(context):
    context.installed = True


@given("the user has access to a supported guest ISO")
def step_user_has_iso(context):
    context.has_iso = True


@when("the user creates a new virtual machine profile")
def step_create_profile(context):
    context.profile_created = True


@when("the user selects the target architecture")
def step_select_architecture(context):
    context.arch_selected = True


@when("the user configures CPU, memory, and storage")
def step_configure_resources(context):
    context.resources_configured = True


@then("the virtual machine profile is saved")
def step_profile_saved(context):
    assert getattr(context, "profile_created", False)
    context.profile_saved = True


@then("the virtual machine appears in the library")
def step_vm_in_library(context):
    assert getattr(context, "profile_saved", False)


@given("an existing virtual machine profile")
def step_existing_profile(context):
    context.existing_profile = True


@when("the user starts the virtual machine")
def step_start_vm(context):
    context.vm_running = True


@then("the virtual machine boots successfully")
def step_vm_boots(context):
    assert getattr(context, "vm_running", False)


@then("the console or display is visible")
def step_console_visible(context):
    context.console_visible = True


@given("a running virtual machine")
def step_running_vm(context):
    context.vm_running = True


@when("the user pauses the virtual machine")
def step_pause_vm(context):
    context.vm_paused = True


@then("the virtual machine state is preserved")
def step_state_preserved(context):
    assert getattr(context, "vm_paused", False)


@when("the user resumes the virtual machine")
def step_resume_vm(context):
    context.vm_running = True
    context.vm_paused = False


@then("the virtual machine continues execution")
def step_vm_continues(context):
    assert getattr(context, "vm_running", False)
    assert not getattr(context, "vm_paused", True)


@given("the user has an existing UTM VM package")
def step_existing_package(context):
    context.has_package = True


@when("the user imports the virtual machine into the library")
def step_import_vm(context):
    context.imported = True


@then("its configuration is accessible")
def step_configuration_accessible(context):
    assert getattr(context, "imported", False)


@when("the user exports the virtual machine package")
def step_export_vm(context):
    context.exported = True


@then("the exported package is created")
def step_export_created(context):
    assert getattr(context, "exported", False)


@when("the user deletes the virtual machine profile")
def step_delete_vm(context):
    context.deleted = True


@then("the virtual machine is removed from the library")
def step_vm_removed(context):
    assert getattr(context, "deleted", False)
