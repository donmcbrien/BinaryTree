# BinaryTree

### Declaration
    public enum BinaryTree<R: BinaryTreeRecordProtocol, K> where K == R.BinaryTreeKey
    
### Overview
A Binary Tree is a recursive structure in that every tree is composed of sub-trees and every sub-tree is a tree which obeys all the invariant rules (except that a sub-tree may have a <r> root). Key tree-maintenance operations are insert and delete.

You use binary trees as data structures to provide rapid access to data. The data stored must conform to the BinaryTreeRecordProtocol which essentially means it should contain a property which conforms to the BinaryTreeKeyProtocol. This latter protocol is not unlike the Comparable protocol in that it shows how records should be ordered in the tree but it also governs the treatment of duplicate records.

### Insertion and Removal
A newly initialised binary tree is always empty. Records can be added singly or in collections using one of the following methods:

    public mutating func insert(_ record: R) -> Bool
// adds one record if permitted (i.e. if duplicates allowed) 
   
    public mutating func insert(_ arrayOfRecords: [R]) -> [R]
// adds multiple record and returns array of records which were rejected

Records can be removed singly or in collections using one of the following methods:

    public mutating func remove(_ key: K) -> R?
// removes the first record, if any, containing the key

    public mutating func removeAll(_ key: K) -> [R]
// only relevant where duplicates are permitted, this method removes all records, if any,
// containg the key, and sorted by the rule in the RedBlackTreeKeyProtocol

### Record Inspection
A number of methods can be used to examing records in the tree without changing the tree:

    public func contains(_ key: K) -> Bool 
// reports whether a record containing the key is present

    public var minimum: R?
// Find the leftmost record

    public var maximum: R?
// Find the rightmost record

    public func fetch(_ key: K) -> R? {
// fetches a copy of the only record (or first when duplicates permitted), if any, containing the key

    public func fetchAll(_ key: K) -> [R]
// only relevant where duplicates are permitted, this method fetches copies of all records, if any,
// containing the key, and sorted by the rule in the RedBlackTreeKeyProtocol

    public func neighboursOf(_ key: K) -> (R?,R?)?
// fetches the immediate neighbours, left and right, of the record containing the key (but only 
    // if such a record) is present in the tree. Duplicates of key are ignored.

    public func neighboursFor(_ key: K, leftRecord: R? = nil, rightRecord: R? = nil) -> (R?,R?)
// fetches the immediate neighbours, left and right, of where a record containing the key would be
// (whether or not such a record is present). Duplicates of key are ignored.

### Tree Inspection
Finally a number of methods can be used to examine the tree in its entirety:

    public var isEmpty: Bool
// is the tree empty?
    
    public var count: Int
// how many records are in the tree?
    
    public var height: Int
// What is the longest path from root to leaf in the tree?

Note also that a printable graphic of the tree can be obtained in the following property:

    public var description: String


### Usage
To use a tree, make your record type conform to BinaryTreeRecordProtocol by adding an extension with a computable property called binaryTreeKey which conforms to BinaryTreeKeyProtocol and make your key type conform to BinaryTreeKeyProtocol by adding the two required computable variables governing duplicates and a method to describe ordering:

    extension MyRecordType: BinaryTreeRecordProtocol {
       public typealias BinaryTreeKey = MyKeyType
       public var binaryTreeKey: BinaryTreeKey { return self.myKey }
    }

    extension MyKeyType: BinaryTreeKeyProtocol {
       public static var duplicatesAllowed: Bool { return false }
       public static var duplicatesUseFIFO: Bool { return false }

       public static func ⊰(lhs: MyKeyType, rhs: MyKeyType) -> BinaryTreeComparator {
           //descending order
          if lhs.myKey > rhs.myKey { return .leftTree }
          if lhs.myKey == rhs.myKey { return .matching }
          return .rightTree
       }
    }

Now you can declare and use a BinaryTree 

    var myBinaryTree = BinaryTree<MyRecordType, MyKeyType>()

### Simple Example

     import Foundation
     import BinaryTree

     struct Foo {
        var id: Int
        var contents: Double
     }

     extension Foo: BinaryTreeRecordProtocol {
        public typealias BinaryTreeKey = Int
        public var binaryTreeKey: BinaryTreeKey { return self.id }
     }
     
     extension Foo: CustomStringConvertible {
        var description: String { return String(format: "%3d:  %7.2f", id, contents) }
     }

     extension Int: BinaryTreeKeyProtocol {
        public static var duplicatesAllowed: Bool { return false }
        public static var duplicatesUseFIFO: Bool { return false }
     
        public static func ⊰(lhs: Int, rhs: Int) -> BinaryTreeComparator {
           // descending order
           if lhs > rhs { return .leftTree }
           if lhs == rhs { return .matching }
           return .rightTree
        }
     }

     var myTree = BinaryTree<Foo,Int>()

     for _ in 0..<100 {
        let key = Int.random(in: 1...1000)
        let record = Foo(id: key, contents: Double.random(in: -1000.0...1000.0))
        if !myTree.insert(record) {
           print("    ",record)
        }
     }

     print("    ",myTree)

These 5 records were refused insertion because their keys were already in use:

     485:  -925.85
     938:  -901.63
     642:  -626.61
     722:  -178.62
     939:  -174.57
     
The tree accepted 95 insertions shown in descending order as required:


                         ┌───◻︎986:  -862.54
                     ┌───◻︎979:   -60.42
                     │   └───◻︎954:  -779.90
                 ┌───◻︎943:  -112.87
                 │   └───◦
             ┌───◻︎939:   168.03
             │   └───◻︎938:   604.14
         ┌───◻︎926:  -145.22
         │   │       ┌───◦
         │   │   ┌───◻︎908:  -367.03
         │   │   │   └───◻︎907:  -238.09
         │   └───◻︎893:  -151.79
         │       │       ┌───◦
         │       │   ┌───◻︎885:   792.12
         │       │   │   │   ┌───◻︎882:   535.76
         │       │   │   └───◻︎878:   -51.62
         │       │   │       └───◻︎835:   383.05
         │       └───◻︎829:  -375.70
         │           └───◦
     ┌───◻︎825:  -286.77
     │   │       ┌───◦
     │   │   ┌───◻︎824:   242.05
     │   │   │   │   ┌───◦
     │   │   │   └───◻︎817:  -465.10
     │   │   │       │   ┌───◻︎807:  -688.95
     │   │   │       └───◻︎802:   371.95
     │   │   │           └───◦
     │   └───◻︎800:   542.51
     │       │       ┌───◦
     │       │   ┌───◻︎767:  -553.86
     │       │   │   │       ┌───◦
     │       │   │   │   ┌───◻︎754:   670.44
     │       │   │   │   │   └───◻︎751:  -413.78
     │       │   │   └───◻︎750:   502.77
     │       │   │       │   ┌───◻︎748:    32.87
     │       │   │       └───◻︎745:  -766.05
     │       │   │           │       ┌───◻︎733:  -144.12
     │       │   │           │   ┌───◻︎727:  -772.21
     │       │   │           │   │   └───◦
     │       │   │           └───◻︎722:   780.07
     │       │   │               └───◦
     │       └───◻︎714:   205.85
     │           │           ┌───◦
     │           │       ┌───◻︎712:   424.28
     │           │       │   │   ┌───◻︎698:  -861.36
     │           │       │   └───◻︎683:  -311.13
     │           │       │       │       ┌───◻︎674:  -755.86
     │           │       │       │   ┌───◻︎663:   -46.72
     │           │       │       │   │   └───◦
     │           │       │       └───◻︎645:   256.03
     │           │       │           │       ┌───◻︎643:  -869.09
     │           │       │           │   ┌───◻︎642:   278.63
     │           │       │           │   │   └───◻︎632:  -318.54
     │           │       │           └───◻︎607:   571.89
     │           │       │               └───◦
     │           │   ┌───◻︎606:   313.46
     │           │   │   └───◻︎605:   237.65
     │           └───◻︎566:   334.38
     │               └───◦
     ◻︎560:  -409.01
     │       ┌───◦
     │   ┌───◻︎555:   115.80
     │   │   │       ┌───◻︎549:   -22.71
     │   │   │   ┌───◻︎530:  -863.79
     │   │   │   │   └───◦
     │   │   └───◻︎520:    86.96
     │   │       │   ┌───◦
     │   │       └───◻︎514:    17.08
     │   │           └───◻︎486:   298.55
     └───◻︎485:  -692.53
         │           ┌───◻︎465:  -514.02
         │       ┌───◻︎455:  -488.92
         │       │   └───◦
         │   ┌───◻︎452:   174.86
         │   │   │       ┌───◦
         │   │   │   ┌───◻︎450:  -568.11
         │   │   │   │   │               ┌───◻︎440:  -343.39
         │   │   │   │   │           ┌───◻︎434:  -361.23
         │   │   │   │   │           │   └───◦
         │   │   │   │   │       ┌───◻︎417:    14.47
         │   │   │   │   │       │   └───◦
         │   │   │   │   │   ┌───◻︎414:   597.51
         │   │   │   │   │   │   └───◦
         │   │   │   │   └───◻︎413:    30.53
         │   │   │   │       └───◻︎399:   984.85
         │   │   └───◻︎377:   362.63
         │   │       │       ┌───◻︎370:  -684.72
         │   │       │   ┌───◻︎342:  -388.16
         │   │       │   │   │           ┌───◻︎334:   963.05
         │   │       │   │   │       ┌───◻︎296:  -926.00
         │   │       │   │   │       │   └───◻︎293:  -401.54
         │   │       │   │   │   ┌───◻︎289:  -813.34
         │   │       │   │   │   │   │           ┌───◻︎277:  -673.86
         │   │       │   │   │   │   │       ┌───◻︎268:  -779.37
         │   │       │   │   │   │   │       │   │   ┌───◻︎264:  -129.29
         │   │       │   │   │   │   │       │   └───◻︎250:  -753.41
         │   │       │   │   │   │   │       │       └───◦
         │   │       │   │   │   │   │   ┌───◻︎232:   417.91
         │   │       │   │   │   │   │   │   │   ┌───◦
         │   │       │   │   │   │   │   │   └───◻︎227:   646.70
         │   │       │   │   │   │   │   │       └───◻︎222:  -987.31
         │   │       │   │   │   │   └───◻︎221:   945.46
         │   │       │   │   │   │       └───◦
         │   │       │   │   └───◻︎219:   433.38
         │   │       │   │       └───◦
         │   │       └───◻︎205:   813.67
         │   │           │       ┌───◦
         │   │           │   ┌───◻︎196:  -362.22
         │   │           │   │   │           ┌───◻︎191:    12.76
         │   │           │   │   │       ┌───◻︎188:   905.71
         │   │           │   │   │       │   └───◦
         │   │           │   │   │   ┌───◻︎175:  -342.07
         │   │           │   │   │   │   └───◻︎173:   -55.28
         │   │           │   │   └───◻︎171:  -422.34
         │   │           │   │       └───◦
         │   │           └───◻︎153:  -909.80
         │   │               │       ┌───◦
         │   │               │   ┌───◻︎113:  -346.91
         │   │               │   │   └───◻︎106:  -304.92
         │   │               └───◻︎105:  -272.38
         │   │                   │       ┌───◦
         │   │                   │   ┌───◻︎103:  -327.30
         │   │                   │   │   └───◻︎ 97:   240.29
         │   │                   └───◻︎ 86:   947.39
         │   │                       │   ┌───◦
         │   │                       └───◻︎ 43:  -680.55
         │   │                           └───◻︎ 37:  -854.68
         └───◻︎ 28:   439.91
             └───◦


