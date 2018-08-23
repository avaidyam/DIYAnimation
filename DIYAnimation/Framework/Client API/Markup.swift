import Foundation.NSXMLParser

// TODO: CAML support for type `com.avaidyam.diyanimation-xml`
// TODO: CodingProxy for some classes? not needed if Codable extension works...
// TODO: support CA_attributes (sliderValue, etc...), attributesForKeyPath, etc

public enum Markup {
    
    // might require state transitions
    
    ///
    public final class Package {
        
        // root must be layer
        
        // read from data or URL to file
        
    }
    
    ///
    class Transformer: NSObject, XMLParserDelegate {
        
        ///
        internal enum Tag: String {
            
            ///
            case layer
            
            ///
            case animation
        }
        
        ///
        internal final class Node {
            
            ///
            let tag: Tag
            
            ///
            let attributes: [String: String]
            
            ///
            var nodes: [Node]
            
            ///
            internal init(tag: Tag, attributes: [String: String] = [:],
                          nodes: [Node] = [])
            {
                self.tag = tag
                self.attributes = attributes
                self.nodes = nodes
            }
        }
        
        ///
        private let parser: XMLParser
        
        ///
        private var stack = [Node]()
        
        ///
        private var tree: Node?
        
        ///
        internal init(data: Data) {
            self.parser = XMLParser(data: data)
            super.init()
            self.parser.delegate = self
        }
        
        ///
        internal func parse() throws -> Node? {
            self.parser.parse()
            if let e = parser.parserError { throw e }
            
            assert(self.stack.isEmpty)
            assert(self.tree != nil)
            return self.tree
        }
        
        ///
        @objc internal func parser(_ parser: XMLParser,
                                   didStartElement elementName: String,
                                   namespaceURI: String?,
                                   qualifiedName qName: String?,
                                   attributes attributeDict: [String : String] = [:])
        {   guard let tag = Tag(rawValue: elementName) else { return }
            
            stack.append(Node(tag: tag, attributes: attributeDict, nodes: []))
        }
        
        ///
        @objc internal func parser(_ parser: XMLParser,
                                   didEndElement elementName: String,
                                   namespaceURI: String?,
                                   qualifiedName qName: String?)
        {   guard let tag = Tag(rawValue: elementName) else { return }
            
            let lastElement = stack.removeLast()
            assert(lastElement.tag == tag)
            
            if let last = stack.last {
                last.nodes += [lastElement]
            } else {
                tree = lastElement
            }
        }
    }
}
