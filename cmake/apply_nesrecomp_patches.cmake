# Apply the small launcher capability bridge missing from the pinned NESRecomp revision.
# Keep the upstream submodule immutable in Git; the patch is reproducibly applied at configure time.
set(_nes_ui_launcher "${NESRECOMP_ROOT}/runner/cyc/cyc_ui_launcher.c")
if(NOT EXISTS "${_nes_ui_launcher}")
    message(FATAL_ERROR "Pinned NESRecomp launcher source is missing: ${_nes_ui_launcher}")
endif()

file(READ "${_nes_ui_launcher}" _nes_ui_source)
set(_nes_ui_original "${_nes_ui_source}")

if(NOT _nes_ui_source MATCHES "io->widescreen = s->view_mode != 0;")
    set(_old "    io->linear_filter = s->linear_filter;\n")
    set(_new "    io->linear_filter = s->linear_filter;\n    io->widescreen = s->view_mode != 0;\n")
    string(FIND "${_nes_ui_source}" "${_old}" _at)
    if(_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch NESRecomp launcher: linear-filter settings hook changed.")
    endif()
    string(REPLACE "${_old}" "${_new}" _nes_ui_source "${_nes_ui_source}")
endif()

string(FIND "${_nes_ui_source}" "    if (!io->widescreen) s->view_mode = 0;" _widescreen_restore_at)
if(_widescreen_restore_at EQUAL -1)
    set(_old "    s->linear_filter = io->linear_filter != 0;\n")
    set(_new "    s->linear_filter = io->linear_filter != 0;\n    if (!io->widescreen) s->view_mode = 0;\n    else if (s->view_mode == 0) s->view_mode = 1;\n")
    string(FIND "${_nes_ui_source}" "${_old}" _at)
    if(_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch NESRecomp launcher: linear-filter restore hook changed.")
    endif()
    string(REPLACE "${_old}" "${_new}" _nes_ui_source "${_nes_ui_source}")
endif()

if(NOT _nes_ui_source MATCHES "gi.widescreen_supported = extras")
    set(_old "    gi.widescreen_supported = 0;\n")
    set(_new "    gi.widescreen_supported = extras && (extras->view_modes & (1u << 1));\n")
    string(FIND "${_nes_ui_source}" "${_old}" _at)
    if(_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch NESRecomp launcher: widescreen capability hook changed.")
    endif()
    string(REPLACE "${_old}" "${_new}" _nes_ui_source "${_nes_ui_source}")
endif()

string(FIND "${_nes_ui_source}" "    (void)extras;\n" _unused_extras_at)
if(NOT _unused_extras_at EQUAL -1)
    string(REPLACE "    (void)extras;\n" "" _nes_ui_source "${_nes_ui_source}")
endif()

string(FIND "${_nes_ui_source}" "extras->set_view_mode(extras->ctx, settings->view_mode)" _apply_view_mode_at)
if(_apply_view_mode_at EQUAL -1)
    set(_old "    from_launcher(&io, settings, shortcuts, count);\n")
    set(_new "    from_launcher(&io, settings, shortcuts, count);\n    if (extras && extras->set_view_mode)\n        (void)extras->set_view_mode(extras->ctx, settings->view_mode);\n")
    string(FIND "${_nes_ui_source}" "${_old}" _at)
    if(_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch NESRecomp launcher: settings-return hook changed.")
    endif()
    string(REPLACE "${_old}" "${_new}" _nes_ui_source "${_nes_ui_source}")
endif()

if(NOT _nes_ui_source STREQUAL _nes_ui_original)
    file(WRITE "${_nes_ui_launcher}" "${_nes_ui_source}")
endif()

message(STATUS "Excitebike: enabled recomp-ui widescreen setting bridge in pinned NESRecomp")


# Apply small, deterministic fixes to the pinned cycle runtime UI sources.
# The upstream submodules stay immutable in Git; this patch is applied before
# their targets are configured and compiled.

# Ensure the in-game Display page exposes the host's actual runtime view modes.
set(_cycle_menu "${NESRECOMP_ROOT}/runner/cyc/cyc_ui_menu.c")
if(NOT EXISTS "${_cycle_menu}")
    message(FATAL_ERROR "Pinned NESRecomp runtime menu source is missing: ${_cycle_menu}")
endif()
file(READ "${_cycle_menu}" _cycle_source)
set(_cycle_original "${_cycle_source}")

set(_old_view_modes [=[
    if (x && x->view_modes && x->set_view_mode) {
        std.features |= RECOMP_RUNTIME_UI_STANDARD_VIEW_MODE;
        std.view_modes = x->view_modes;
    }
]=])
set(_new_view_modes [=[
    if (x && x->get_view_mode && x->set_view_mode) {
        std.features |= RECOMP_RUNTIME_UI_STANDARD_VIEW_MODE;
        std.view_modes = x->view_modes
            ? x->view_modes
            : (RECOMP_RUNTIME_UI_VIEW_MODE_NATIVE |
               RECOMP_RUNTIME_UI_VIEW_MODE_FIXED_16_9 |
               RECOMP_RUNTIME_UI_VIEW_MODE_ADAPTIVE);
    }
]=])
string(FIND "${_cycle_source}" "${_old_view_modes}" _view_old_at)
if(NOT _view_old_at EQUAL -1)
    string(REPLACE "${_old_view_modes}" "${_new_view_modes}" _cycle_source "${_cycle_source}")
else()
    string(FIND "${_cycle_source}" "${_new_view_modes}" _view_new_at)
    if(_view_new_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch NESRecomp runtime menu: View mode registration block changed.")
    endif()
endif()

if(NOT _cycle_source STREQUAL _cycle_original)
    file(WRITE "${_cycle_menu}" "${_cycle_source}")
endif()

# Fix the in-game settings panel. A section click must enter the section in
# both the narrow and two-column layouts. Hover can preview another section
# without accidentally leaving the current page-navigation state.
set(_runtime_ui "${NESRECOMP_RECOMP_UI}/src/common/backends/imgui/runtime_ui_imgui.cpp")
if(NOT EXISTS "${_runtime_ui}")
    message(FATAL_ERROR "Pinned recomp-ui runtime renderer is missing: ${_runtime_ui}")
endif()
file(READ "${_runtime_ui}" _runtime_source)
set(_runtime_original "${_runtime_source}")

set(_old_section [=[
void draw_sections(RecompRuntimeUi *ui, const LauncherTheme &theme,
                   bool enter_on_click) {
    for (size_t index = 0; index < ui->section_count; ++index) {
        ImGui::PushID(static_cast<int>(index));
        const bool selected = index == ui->section_index;
        const bool clicked = ImGui::Selectable(ui->sections[index], selected, 0,
                                               ImVec2(0.0f, theme.row_height));
        if ((clicked || ImGui::IsItemHovered()) &&
            (index != ui->section_index || (clicked && enter_on_click))) {
            const int was_in_section = ui->in_section;
            recomp_runtime_ui_enter_section(ui, index);
            if (!(clicked && enter_on_click)) ui->in_section = was_in_section;
        }
        ImGui::PopID();
    }
}
]=])
set(_new_section [=[
void draw_sections(RecompRuntimeUi *ui, const LauncherTheme &theme,
                   bool enter_on_click) {
    (void)enter_on_click;
    for (size_t index = 0; index < ui->section_count; ++index) {
        ImGui::PushID(static_cast<int>(index));
        const bool selected = index == ui->section_index;
        const bool clicked = ImGui::Selectable(ui->sections[index], selected, 0,
                                               ImVec2(0.0f, theme.row_height));
        const bool hovered = ImGui::IsItemHovered();
        if (clicked) {
            /* A click always opens the selected page, even if it was already highlighted. */
            recomp_runtime_ui_enter_section(ui, index);
        } else if (hovered && index != ui->section_index) {
            /* Hover previews a page but preserves the current navigation level. */
            const int was_in_section = ui->in_section;
            recomp_runtime_ui_enter_section(ui, index);
            ui->in_section = was_in_section;
        }
        ImGui::PopID();
    }
}
]=])
string(FIND "${_runtime_source}" "${_old_section}" _section_old_at)
if(NOT _section_old_at EQUAL -1)
    string(REPLACE "${_old_section}" "${_new_section}" _runtime_source "${_runtime_source}")
else()
    string(FIND "${_runtime_source}" "A click always opens the selected page" _section_new_at)
    if(_section_new_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch recomp-ui runtime menu navigation: section renderer changed.")
    endif()
endif()

# Runtime setting descriptions must wrap inside their row rather than draw
# over values or outside the settings panel. Row height follows the wrapped
# description so the containing child can scroll normally.
set(_old_row_height [=[
        const float row_h = item->description && item->description[0]
                                ? theme.row_height + theme.spacing_sm
                                : theme.row_height;
]=])
set(_new_row_height [=[
        const float description_width = std::max(
            1.0f, ImGui::GetContentRegionAvail().x - theme.spacing_md * 2.0f);
        const ImVec2 description_size =
            item->description && item->description[0]
                ? ImGui::CalcTextSize(item->description, nullptr, false,
                                      description_width)
                : ImVec2(0.0f, 0.0f);
        const float row_h = theme.row_height +
            (description_size.y > 0.0f
                ? theme.spacing_sm + description_size.y
                : 0.0f);
]=])
string(FIND "${_runtime_source}" "${_old_row_height}" _row_old_at)
if(NOT _row_old_at EQUAL -1)
    string(REPLACE "${_old_row_height}" "${_new_row_height}" _runtime_source "${_runtime_source}")
else()
    string(FIND "${_runtime_source}" "const float description_width = std::max(" _row_new_at)
    if(_row_new_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch recomp-ui runtime menu: setting row sizing changed.")
    endif()
endif()

set(_old_description [=[
        if (item->description && item->description[0]) {
            draw->AddText(ImVec2(start.x + theme.spacing_md,
                                start.y + theme.spacing_sm +
                                    ImGui::GetTextLineHeight() + 2.0f),
                          u32(theme.text_muted), item->description);
        }
]=])
set(_new_description [=[
        if (item->description && item->description[0]) {
            const ImVec2 description_pos(
                start.x + theme.spacing_md,
                start.y + theme.spacing_sm + ImGui::GetTextLineHeight() + 2.0f);
            const ImVec2 description_max(
                end.x - theme.spacing_md, start.y + row_h);
            draw->PushClipRect(description_pos, description_max, true);
            draw->AddText(ImGui::GetFont(), ImGui::GetFontSize(),
                          description_pos, u32(theme.text_muted),
                          item->description, nullptr, description_width);
            draw->PopClipRect();
        }
]=])
string(FIND "${_runtime_source}" "${_old_description}" _description_old_at)
if(NOT _description_old_at EQUAL -1)
    string(REPLACE "${_old_description}" "${_new_description}" _runtime_source "${_runtime_source}")
else()
    string(FIND "${_runtime_source}" "description_max(" _description_new_at)
    if(_description_new_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch recomp-ui runtime menu: setting description renderer changed.")
    endif()
endif()

if(NOT _runtime_source STREQUAL _runtime_original)
    file(WRITE "${_runtime_ui}" "${_runtime_source}")
endif()


# Keep the HD texture-pack output-scale selector with the other Display options.
# This is the HD-pack rendering scale, not a claim that the NES framebuffer changes size.
set(_old_hd_row "add(\"cyc.hd.resolution\", \"Graphics\", \"HD resolution\",")
set(_new_hd_row "add(\"cyc.hd.resolution\", \"Display\", \"HD resolution\",")
string(FIND "${_cycle_source}" "${_old_hd_row}" _hd_row_old_at)
if(NOT _hd_row_old_at EQUAL -1)
    string(REPLACE "${_old_hd_row}" "${_new_hd_row}" _cycle_source "${_cycle_source}")
else()
    string(FIND "${_cycle_source}" "${_new_hd_row}" _hd_row_new_at)
    if(_hd_row_new_at EQUAL -1)
        message(FATAL_ERROR "Cannot patch NESRecomp runtime menu: HD resolution row changed.")
    endif()
endif()
if(NOT _cycle_source STREQUAL _cycle_original)
    file(WRITE "${_cycle_menu}" "${_cycle_source}")
endif()

message(STATUS "Excitebike: in-game Display → View mode registered")
message(STATUS "Excitebike: fixed runtime settings navigation and wrapped setting descriptions")
