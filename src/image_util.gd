extends Node

class_name ImageUtil

static func TextureFromFile(path: String):
	var pic = Image.new()
	pic.load(path)
	return ImageTexture.create_from_image(pic)
