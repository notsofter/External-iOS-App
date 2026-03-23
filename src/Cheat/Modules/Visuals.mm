#include "Visuals.h"

#include <Foundation/Foundation.h>
#include <cmath>

#include "../ModulesSharedData.h"

static ModulesSharedData *modulesSharedData = nullptr;
static EntityDataList *entity_data_list_module = nullptr;
static Camera *camera = nullptr;

static ImFont *text_font = nullptr;
static int screen_w, screen_h = 0;

const char *Visuals::getModuleName() {
	return "Visuals";
}

void Visuals::OnInit(void *shared_data) {
	modulesSharedData = (ModulesSharedData *)shared_data;
	entity_data_list_module = modulesSharedData->modulesManager->getModule<EntityDataList>();
	camera = modulesSharedData->modulesManager->getModule<Camera>();

	text_font = modulesSharedData->text_font;
	screen_w = modulesSharedData->screen_w;
	screen_h = modulesSharedData->screen_h;
}

void Visuals::OnUpdate() {
	screen_w = modulesSharedData->screen_w;
	screen_h = modulesSharedData->screen_h;

	if (!Vars::visuals.isOn)
		return;

	std::vector<EntityDataList::EntityData> &entity_data_list = entity_data_list_module->getEntityDataList();
	for (auto current_entity_data : entity_data_list) {

		if (!current_entity_data.on_screen) {
			if (Vars::visuals_offscreen.isOn)
				DrawOffscreen(current_entity_data);
			continue;
		}

		if (Vars::visuals_line.isOn)
			DrawLine(current_entity_data);

		if (Vars::visuals_box.isOn)
			DrawRoundedBox(current_entity_data);

		if (Vars::visuals_skeleton.isOn)
			DrawSkeleton(current_entity_data);

		if (Vars::visuals_infobar.isOn)
			DrawInfoBar(current_entity_data);

		if (Vars::visuals_weaponname.isOn)
			DrawWeaponName(current_entity_data);

      if (Vars::visuals_box.isOn || Vars::visuals_line.isOn || Vars::visuals_skeleton.isOn || Vars::visuals_infobar.isOn || Vars::visuals_weaponname.isOn)
         DrawWatermark(current_entity_data);

	}

	std::vector<EntityDataList::EntityHitData> &entity_hit_data_list = entity_data_list_module->getEntityHitDataList();
	for (auto current_hit_data : entity_hit_data_list) {
		DrawHitData(current_hit_data);
	}

	std::vector<EntityDataList::EntityFootstepData> &entity_footstep_data_list = entity_data_list_module->getEntityFootstepDataList();
	for (auto current_footstep_data : entity_footstep_data_list) {
		DrawFootstep(current_footstep_data);
	}
}

void Visuals::DrawSkeleton(EntityDataList::EntityData &entity_data) {
	#define _ entity_data.screen_positions.

	float head_radius = fabs(_ HeadTop.y - _ Head.y) / 2.f;
	ImVec2 head_screen = _ Head;
		head_screen.y -= head_radius;

	ImColor skeletonColor = (entity_data.visible) ? ImColor(255, 255, 0) : ImColor(0, 255, 0);

	ImGui::GetForegroundDrawList()->AddCircle(head_screen, head_radius, skeletonColor, 100, 1.25f);

	ImGui::GetForegroundDrawList()->AddLine(_ Head, _ Neck, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ Neck, _ Spine3, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ Spine3, _ Spine2, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ Spine2, _ Spine1, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ Spine1, _ Hip, skeletonColor, 1.25f);

	ImGui::GetForegroundDrawList()->AddLine(_ Neck, _ LeftShoulder, skeletonColor, 1.25f);			ImGui::GetForegroundDrawList()->AddLine(_ Neck, _ RightShoulder, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ LeftShoulder, _ LeftUpperarm, skeletonColor, 1.25f);	ImGui::GetForegroundDrawList()->AddLine(_ RightShoulder, _ RightUpperarm, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ LeftUpperarm, _ LeftForearm, skeletonColor, 1.25f);	ImGui::GetForegroundDrawList()->AddLine(_ RightUpperarm, _ RightForearm, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ LeftForearm, _ LeftHand, skeletonColor, 1.25f);		ImGui::GetForegroundDrawList()->AddLine(_ RightForearm, _ RightHand, skeletonColor, 1.25f);

	ImGui::GetForegroundDrawList()->AddLine(_ Hip, _ LeftUpLeg, skeletonColor, 1.25f);				ImGui::GetForegroundDrawList()->AddLine(_ Hip, _ RightUpLeg, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ LeftUpLeg, _ LeftLeg, skeletonColor, 1.25f);			ImGui::GetForegroundDrawList()->AddLine(_ RightUpLeg, _ RightLeg, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ LeftLeg, _ LeftFoot, skeletonColor, 1.25f);			ImGui::GetForegroundDrawList()->AddLine(_ RightLeg, _ RightFoot, skeletonColor, 1.25f);
	ImGui::GetForegroundDrawList()->AddLine(_ LeftFoot, _ LeftToeBase, skeletonColor, 1.25f);		ImGui::GetForegroundDrawList()->AddLine(_ RightFoot, _ RightToeBase, skeletonColor, 1.25f);
}

void Visuals::DrawDefaultBox(EntityDataList::EntityData &entity_data, float rounding) {
	#define _ entity_data.screen_positions.

	ImVec2 box_top_left_corner_screen = _ RootTop;
	ImVec2 box_bottom_right_corner_screen = _ Root;
	
	float box_w = fabs(box_top_left_corner_screen.y - box_bottom_right_corner_screen.y) / 3;

	box_top_left_corner_screen.x -= box_w;
	box_bottom_right_corner_screen.x += box_w;

	ImGui::GetForegroundDrawList()->AddRect(box_top_left_corner_screen, box_bottom_right_corner_screen, ImColor(255, 255, 255), rounding, 0.f, 1.5f);
}

void Visuals::DrawRoundedBox(EntityDataList::EntityData &entity_data) {
	return DrawDefaultBox(entity_data, 1.5f);
}

void Visuals::DrawWeaponName(EntityDataList::EntityData &entity_data) {
	#define _ entity_data.screen_positions.

	char *weaponName = entity_data.weaponName;

	ImVec2 stringSize = text_font->CalcTextSizeA(11.f, FLT_MAX, -1.f, weaponName, NULL, NULL);

	ImGui::GetForegroundDrawList()->AddText(text_font, 11.f, ImVec2(_ Root.x - (stringSize.x / 2), _ Root.y + 2.f), ImColor(255, 255, 255, 255), weaponName);
}

void Visuals::DrawInfoBar(EntityDataList::EntityData &entity_data) {
	#define _ entity_data.screen_positions.

	char *entityName = entity_data.entityName;

	ImVec2 stringSize = text_font->CalcTextSizeA(11.f, FLT_MAX, -1.f, entityName, NULL, NULL);

	float header_w = fabs(_ Head.y - _ Root.y);
	float header_h = stringSize.y + 7.5f;
	float header_l = _ RootTop.x - (header_w / 2.25f) - (entity_data.distance / 4) - (stringSize.x / 2);
	float header_r = _ RootTop.x + (header_w / 2.25f) + (entity_data.distance / 4) + (stringSize.x / 2);

	ImGui::GetForegroundDrawList()->AddRectFilled(ImVec2(header_l, _ RootTop.y - 5.f - header_h), ImVec2(header_r,  _ RootTop.y - 5.f), ImColor(0, 0, 0, 150), 3);
	ImGui::GetForegroundDrawList()->AddText(text_font, 11.f, ImVec2(_ Root.x - (stringSize.x / 2), _ RootTop.y - 5.f - ((header_h / 2) + stringSize.y / 2)), ImColor(255, 255, 255, 255), entityName);

	float hp_r = ((header_r - header_l) / 100) * entity_data.health;
	float hp_h = 5.f - (((header_h / 2) - stringSize.y) / 2);
	ImGui::GetForegroundDrawList()->AddRectFilled(ImVec2(header_l + hp_r,  _ RootTop.y - hp_h), ImVec2(header_l, _ RootTop.y - 5.f), ImColor(0, 255, 0, 150), 3, ImDrawFlags_RoundCornersBottomLeft | ImDrawFlags_RoundCornersBottomRight);
}

void Visuals::DrawLine(EntityDataList::EntityData &entity_data) {
	#define _ entity_data.screen_positions.

	ImGui::GetForegroundDrawList()->AddLine(ImVec2(screen_w / 2, 15), _ RootTop, ImColor(255, 255, 255), 1.5f);
}

float clamp(float value, float min_val, float max_val) {
    return (value < min_val) ? min_val : (value > max_val) ? max_val : value;
}

void rotate_points(Vector3* points, float rotation) {
    Vector3 points_center = (points[0] + points[1] + points[2]) / 3;
    for (int k = 0; k < 3; k++) {
        auto& point = points[k];
        point.x -= points_center.x;
        point.y -= points_center.y;

        const auto temp_x = point.x;
        const auto temp_y = point.y;

        const auto theta = rotation * Deg2Rad;
        const auto c = cos(theta);
        const auto s = sin(theta);

        point.x = temp_x * c - temp_y * s;
        point.y = temp_x * s + temp_y * c;

        point.x += points_center.x;
        point.y += points_center.y;
    }
}

void Visuals::DrawOffscreen(EntityDataList::EntityData& entity_data) {
	#define _ entity_data.screen_positions.

	EntityDataList::EntityData& local_entity_data = entity_data_list_module->getLocalEntityData();

	float currentPitch = local_entity_data.rotation.x;
	float currentYaw = local_entity_data.rotation.y;

	Vector3 direction_to_entity = entity_data.positions.Head - local_entity_data.positions.Head;
	Vector3 angles = Quaternion::ToEuler(Quaternion::LookRotation(direction_to_entity));

	float size = Vars::visuals_offscreen_size.value;

	Vector2 screen_center = {(float)screen_w / 2, (float)screen_h / 2};

	float angle_yaw_rad = (angles.y - currentYaw - 90.0f) * Deg2Rad;

	float radius = Vars::visuals_offscreen_radius.value;

	float new_point_x = screen_center.x + (radius * cos(angle_yaw_rad));
	float new_point_y = screen_center.y + (radius * sin(angle_yaw_rad));

	Vector3 points[3] = {
		Vector3(new_point_x - size, new_point_y - size, 0),
		Vector3(new_point_x + size + (size / 4), new_point_y, 0),
		Vector3(new_point_x - size, new_point_y + size, 0)
	};

	float angle_deg = angles.y - currentYaw - 90.0f;
	rotate_points(points, angle_deg);

	ImColor arrow_color = entity_data.visible ? ImColor(255, 255, 0) : ImColor(255, 255, 255);
	ImGui::GetForegroundDrawList()->AddTriangleFilled(ImVec2(points[0].x, points[0].y), ImVec2(points[1].x, points[1].y), ImVec2(points[2].x, points[2].y), arrow_color);
}

HIKARI_BRANCHING
HIKARI_STRING_ENCRYPTION
void Visuals::DrawWatermark(EntityDataList::EntityData &entity_data) {
	#define _ entity_data.screen_positions.

	char *watermark_name = "gh.notsofter";

	ImVec2 stringSize = text_font->CalcTextSizeA(11.f, FLT_MAX, -1.f, watermark_name, NULL, NULL);
	if (Vars::visuals_weaponname.isOn) {
		stringSize = text_font->CalcTextSizeA(11.f, FLT_MAX, -1.f, watermark_name, NULL, NULL);
		stringSize.y += 2.f;
	}
	else
		stringSize.y = 2.f;

	ImGui::GetForegroundDrawList()->AddText(text_font, 11.f, ImVec2(_ Root.x - (stringSize.x / 2), _ Root.y + stringSize.y), ImColor(255, 255, 255, 255), watermark_name);
}

void Visuals::DrawHitData(EntityDataList::EntityHitData &entity_hit_data) {

	char hit_damage_text[8];
	sprintf(hit_damage_text, "-%d", entity_hit_data.damage);

	float text_font_size = 15.f;

	if (entity_hit_data.damage > 40.f)
		text_font_size = 16.f;
	if (entity_hit_data.damage > 55.f)
		text_font_size = 17.f;
	if (entity_hit_data.damage > 75.f)
		text_font_size = 18.f;
	if (entity_hit_data.damage > 90.f)
		text_font_size = 19.f;

	float t = (float)entity_hit_data.ticks_left / EntityDataList::EntityHitData::max_ticks;
	float color_alpha = 1.0f - (1.0f - t) * (1.0f - t);

	float damage_ratio = std::min(entity_hit_data.damage / 100.f, 1.f);
	int red = 255;
	int green = 255 * (1.f - damage_ratio);
	int blue = 0;

	ImVec2 stringSize = text_font->CalcTextSizeA(text_font_size, FLT_MAX, -1.f, hit_damage_text, NULL, NULL);

	ImVec2 textPos(entity_hit_data.screen.x - (stringSize.x / 2), entity_hit_data.screen.y - (stringSize.y / 2));

	ImColor white_color(255, 255, 255, (int)(color_alpha * 255));

	ImGui::GetForegroundDrawList()->AddText(text_font, text_font_size, ImVec2(textPos.x - 1, textPos.y), white_color, hit_damage_text);
	ImGui::GetForegroundDrawList()->AddText(text_font, text_font_size, ImVec2(textPos.x + 1, textPos.y), white_color, hit_damage_text);
	ImGui::GetForegroundDrawList()->AddText(text_font, text_font_size, ImVec2(textPos.x, textPos.y - 1), white_color, hit_damage_text);
	ImGui::GetForegroundDrawList()->AddText(text_font, text_font_size, ImVec2(textPos.x, textPos.y + 1), white_color, hit_damage_text);
	ImGui::GetForegroundDrawList()->AddText(text_font, text_font_size, ImVec2(textPos.x - 1, textPos.y - 1), white_color, hit_damage_text);
	ImGui::GetForegroundDrawList()->AddText(text_font, text_font_size, ImVec2(textPos.x + 1, textPos.y - 1), white_color, hit_damage_text);
	ImGui::GetForegroundDrawList()->AddText(text_font, text_font_size, ImVec2(textPos.x - 1, textPos.y + 1), white_color, hit_damage_text);
	ImGui::GetForegroundDrawList()->AddText(text_font, text_font_size, ImVec2(textPos.x + 1, textPos.y + 1), white_color, hit_damage_text);

	ImGui::GetForegroundDrawList()->AddText(
		text_font, text_font_size, 
		textPos, 
		ImColor(red, green, blue, (int)(color_alpha * 255)), 
		hit_damage_text
	);
}

void Visuals::DrawFootstep(EntityDataList::EntityFootstepData &entity_footstep_data) {

	const int num_segments = 75;

	float angle_step = 2 * M_PI / num_segments;

	float t = (float)entity_footstep_data.ticks_left / EntityDataList::EntityFootstepData::max_ticks;
	float radius = EntityDataList::EntityFootstepData::min_radius + (EntityDataList::EntityFootstepData::max_radius - EntityDataList::EntityFootstepData::min_radius) * (1.0f - t);

	float color_alpha = 1.0f - (1.0f - t) * (1.0f - t);

	ImVec2 previous_circle_screen_point;
	for (int i = 0; i <= num_segments; ++i) {
		float angle = i * angle_step;

			Vector3 circle_point = entity_footstep_data.position;
				circle_point.x += radius * cos(angle);
				circle_point.z += radius * sin(angle);

			ImVec2 circle_screen_point;
			// WorldToScreen использовал матрицу камеры, но этот код вырезан из проекта, написать его можно самостоятельно.
			if (!camera->WorldToScreen(circle_point, &circle_screen_point))
				return;

		if (i)
			ImGui::GetForegroundDrawList()->AddLine(
				previous_circle_screen_point, 
				circle_screen_point, 
				ImColor(255, 255, 255, (int)(color_alpha * 255)), 
				0.65f
			);

		previous_circle_screen_point = circle_screen_point;
	}
}
