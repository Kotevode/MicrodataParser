import PackageDescription

let package = Package(
    name: "MicrodataParser",
    dependencies: [
		.Package(url: "https://github.com/tid-kijyun/Kanna.git", majorVersion: 2)	
    ],
	exclude: [
		"Tests"
	]
)
