#include "Camera.h"

const char *Camera::getModuleName() {
	return "Camera";
}

HIKARI_ALL_OBF
void Camera::OnInit(void *shared_data) {
	(void)shared_data;
}

HIKARI_BRANCHING
HIKARI_STRING_ENCRYPTION
void Camera::OnUpdate() {
	// Код матрицы камеры из проекта вырезан, написать его вы можете сами как хотите.
}

bool Camera::WorldToScreen(Vector3 position, ImVec2 *out) {
	(void)position;
	(void)out;

	// WorldToScreen использовал матрицу камеры, но этот код вырезан из проекта, написать его можно самостоятельно.
	return false;
}
