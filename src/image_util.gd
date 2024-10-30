extends Node

class_name ImageUtil

static func TextureFromFile(path: String) -> ImageTexture:
	var pic = Image.new()
	pic.load(path)
	return ImageTexture.create_from_image(pic)
