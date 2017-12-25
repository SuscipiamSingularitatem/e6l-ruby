require "Qt"

module E6lQtGUI
	THUMB_SIZE = [150, 150]

	# Instantiate, then call the show method to set the current Qt App's content to a simple image display.
	class ImageDisplayWindow < Qt::MainWindow
		def initialize(image_path, window_title, window_dims)
			super(nil)
			image_label = Qt::Label.new
			image_label.pixmap = Qt::Pixmap.fromImage Qt::Image.new(image_path)
			image_label.setAlignment(Qt::AlignHCenter.to_i | Qt::AlignVCenter.to_i)
			setCentralWidget image_label
			setWindowTitle window_title
			resize(window_dims[0], window_dims[1])
		end
	end

	# Creates and runs a Qt App which displays a post's "preview" (thumbnail).
	def E6lQtGUI.single_preview(post)
		path = case post.ext
		when "gif", "jpg", "png"
			post.dl_preview
			post.preview_tempfile.path
		when "swf", "webm"
			"img#{File::SEPARATOR}#{post.ext == "swf" ? "download" : "webm"}-preview.png"
		end
		qt_app = Qt::Application.new(ARGV)
		ImageDisplayWindow.new(path, "e6##{post.raw_hash["id"]} (.#{post.ext})", THUMB_SIZE).show
		qt_app.exec
	end

	# Creates and runs a Qt App which displays a post's "sample" (scaled-down, med-res version).
	def E6lQtGUI.single_sample(post)
		case post.ext
		when "gif", "jpg", "png"
			post.dl_sample
			path = post.sample_tempfile.path
			window_dims = [post.raw_hash["sample_width"], post.raw_hash["sample_height"]]
		when "swf", "webm"
			path = "img#{File::SEPARATOR}#{post.ext == "swf" ? "download" : "webm"}-preview.png"
			window_dims = THUMB_SIZE
		end
		qt_app = Qt::Application.new(ARGV)
		ImageDisplayWindow.new(path, "e6##{post.raw_hash["id"]} (.#{post.ext})", window_dims).show
		qt_app.exec
	end
end
