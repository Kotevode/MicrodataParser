import XCTest
import SwiftyJSON
@testable import MicrodataParser

class MicrodataParserTests: XCTestCase {
    
    let tests = [
        "test"
    ]
    
    func testCanExtendDictionary() {
        let item = MicrodataItem()
        
        item["a"] = "a"
        XCTAssertEqual(item["a"] as! String, "a")
        item["a"] = "b"
        XCTAssertEqual(item["a"] as! [String], ["a","b"])
        
    }
    
    func makeTests() -> [(page: String, item: String)] {
        let bundle = Bundle(for: MicrodataParserTests.self)
        return tests.map { (test) -> (page: String, item: String) in
            let pagePath = bundle.path(forResource: name, ofType: "html")!
            let page = try! String(contentsOfFile: pagePath)
            let itemPath = bundle.path(forResource: name, ofType: "json")!
            let item = try! String(contentsOfFile: itemPath)
            return (page: page, item: item)
        }
    }
    
    //    func testCanParsePage() {
    //        let testCases = makeTests()
    //        for testCase in testCases {
    //            let expected = testCase.item
    //            let parsed = try! MicrodataParser.parse(html: testCase.page).first!
    //            XCTAssertEqual(JSON(parsed).string!, JSON(parsed).string!)
    //        }
    //    }
    
    func testCanParseRandomPage() {
        let str = try! String(contentsOf: URL(string: "http://eda.ru/recepty/vypechka-deserty/brauni-brownie-20955")!)
        let parser = MicrodataParser()
        dump(try! parser.parse(html: str))
    }
    
    func testCanParseRandomPageWithOptions() {
        let str = try! String(contentsOf: URL(string: "http://eda.ru/recepty/vypechka-deserty/brauni-brownie-20955")!)
        let parser = MicrodataParser(propertyTransforms: [
            "recipeIngredient" : { (element, _) in
                guard
                    let parent = element.at_xpath("../.."),
                    let jsonString = parent["data-ingredient-object"]
                    else {
                        return nil
                }
                let json = JSON(parseJSON: jsonString)
                return [
                    "name" : json["name"].stringValue,
                    "amount" : json["amount"].stringValue
                ]
            }
            ])
        dump(try! parser.parse(html: str))
    }
    
    static var allTests : [(String, (MicrodataParserTests) -> () throws -> Void)] {
        return [
            ("testCanExtendDictionary", testCanExtendDictionary)
        ]
    }
}
