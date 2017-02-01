import PackageDescription

let package = Package(
    name: "MicrodataParser",
    dependencies: [
		.Package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", versions: Version(1,0,0)..<Version(3, .max, .max)),
		.Package(url: "https://github.com/tid-kijyun/Kanna.git", majorVersion: 2)	
    ]
)
