extends Object
class_name CharacterRoleLibrary

const ROLE_DIRECTORY := "res://resources/characters"

static func load_roles() -> Array[CharacterClassResource]:
	var roles: Array[CharacterClassResource] = []
	var directory := DirAccess.open(ROLE_DIRECTORY)
	if directory == null:
		return roles

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			var resource := load(ROLE_DIRECTORY + "/" + file_name)
			if resource is CharacterClassResource:
				roles.append(resource)
		file_name = directory.get_next()
	directory.list_dir_end()

	roles.sort_custom(func(a: CharacterClassResource, b: CharacterClassResource) -> bool:
		return a.role_id < b.role_id
	)
	return roles

static func find_role(role_id: String) -> CharacterClassResource:
	for role_resource in load_roles():
		if role_resource.role_id == role_id:
			return role_resource

	return null
