//
//  BinaryTree.swift
//  BinaryTree
//
//  Created by Don McBrien on 20/11/2021.
//  Copyright © 2021 Don McBrien. All rights reserved.
//

import Foundation

//MARK: - BINARY TREE
/// A data structure used to store objects (herein called records) in an
/// order determined by its `binaryTreeKey` member.
///
/// The tree must conform to `BinaryTreeRecordProtocol` which simply
/// requires that it has a member (usually a computed variable provided in
/// an extension to the record object) which acts as the key to determine
/// ordering. The key must conform to the `BinaryTreeKeyProtocol`
/// which requires that it defines the `⊰` operator which determines ordering
/// and two boolean functions to set whether keys must be unique or not and
/// whether they are stored in FIFO or LIFO order.

public indirect enum BinaryTree<R: BinaryTreeRecordProtocol, K>
where K == R.BinaryTreeKey {
   case empty
   case node(_ record: R,
             _ left: BinaryTree<R,K>,
             _ right: BinaryTree<R,K>)
   
   public init() { self = .empty }
}

//MARK: - PROTOCOLS
/// Protocol adopted by records stored in an `BinaryTree`.
///
/// Defines the key used by records stored in a BinaryTree. They must
/// conform to the `BinaryTreeOrderingProtocol`.
public protocol BinaryTreeRecordProtocol {
   associatedtype BinaryTreeKey: BinaryTreeKeyProtocol
   var redBlackTreeKey: BinaryTreeKey { get }
}

/// Protocol adopted by the keys of records stored in an `BinaryTree`.
///
/// Defines the `⊰` operator used to determine the order of keys and
/// boolean properties to set whether keys must be unique or not and
/// whether they are stored in FIFO or LIFO order.
public protocol BinaryTreeKeyProtocol {
   /// Comparison operator for ordering a BinaryTree. Used to
   /// select which branch to follow when navigating a `BinaryTree`
   /// by comparing the key sought with the key at the current
   /// position in the tree.
   ///
   /// Beware: records are stored in the tree based on the evaluation of `⊰`
   /// at the moment of insertion. If this evaluation can change the
   /// position in the tree will not change unless the object is explicitly
   /// removed from the tree before its position would change and reinserted
   /// after. This behaviour is intentional to support managing a list based
   /// on dynamic keys.
   static func ⊰(lhs: Self,rhs: Self) -> BinaryTreeComparator
   /// Indicates whether the BinaryTree can have duplicate entries.
   ///
   /// - Defaults to `false` meaning duplicate entries should be ignored on insertion.
   /// - Should be overridden to `true` if duplicates are permitted.
   static var duplicatesAllowed: Bool { get }
   /// Indicates how duplicate entries are extracted from the BinaryTree.
   /// Is meaningless if `duplicatesAllowed` is `false`
   ///
   /// - Defaults to `true` meaning deletion is First-In-First-Out.
   /// - Should be overridden to `false` if deletion is Last-In-First-Out.
   static var duplicatesUseFIFO: Bool { get }
}

extension BinaryTreeKeyProtocol {
   /// Default implementation. If truee, dplicate entries should be ignored
   /// when inserting records in the tree.
   static var duplicatesAllowed: Bool { return false }
   /// default implementation. Deletion is First-In-First-Out. Otherwise First-In-First-Out.
   static var duplicatesUseFIFO: Bool { return true }
}

//MARK:- Contains/Neighbours.  Examine the Tree without changing it.
extension BinaryTree {
   /// Recursively checks if `BinaryTree` contains `key`?
   ///
   /// - Parameter key: key part of desired record
   /// - Returns: `true` or `false`
   public func contains(_ key: K) -> Bool {
      switch self {
         case .empty: return false
         case let .node(record, left, right):
            switch key ⊰ record.redBlackTreeKey {
               case .matching: return true
               case .leftTree: return left.contains(key)
               case .rightTree: return right.contains(key)
            }
      }
   }
   
   /// Fetches the next record containing `key` (or, if duplicates are permitted,
   /// the leftmost if the tree uses FIFO, the rightmost if it doesn't).
   ///
   /// Different from `contains(_:)` as it returns the record. The tree is unchanged.
   ///
   /// See also: `contains(_:) -> Bool`, `remove(_:) -> R?`
   /// - Parameter key: key part of desired record
   /// - Returns: the corresponding record or `nil` if not found
   public func fetch(_ key: K) -> R? {
      switch self {
         case .empty: return nil
         case let .node(record, left, right):
            switch (key ⊰ record.redBlackTreeKey, K.duplicatesAllowed, K.duplicatesUseFIFO) {
               case (.matching, false, _): return record
               case (.matching, true, let usesFIFO):
                  var e: R?
                  if usesFIFO { e = left.fetch(key) }
                  else { e = right.fetch(key) }
                  if e == nil { return record }
                  else { return e }
               case (.leftTree, _, _): return left.fetch(key)
               case (.rightTree, _, _): return right.fetch(key)
            }
      }
   }
   
   /// Fetches all records containing `key` (in the order corresponding to the
   /// the order of deletion according to the usesFIFO rule).
   ///
   /// The tree is unchanged.
   ///
   /// See also: `removeAll() -> [R]`
   /// - Parameter key: key part of desired record
   /// - Returns: an array of records; may be empty.
   public func fetchAll(_ key: K) -> [R] {
      var result = [R]()
      switch self {
         case .empty:
            return result
         case let .node(record, left, right):
            switch (key ⊰ record.redBlackTreeKey, K.duplicatesAllowed, K.duplicatesUseFIFO) {
               case (.matching, false, _):
                  result.append(record)
               case (.matching, true, let usesFIFO):
                  if usesFIFO {
                     result.append(contentsOf: left.fetchAll(key))
                     result.append(record)
                     result.append(contentsOf: right.fetchAll(key))
                  } else {
                     result.append(contentsOf: right.fetchAll(key))
                     result.append(record)
                     result.append(contentsOf: left.fetchAll(key))
                  }
               case (.leftTree, _, _):
                  result.append(contentsOf: left.fetchAll(key))
               case (.rightTree, _, _):
                  result.append(contentsOf: right.fetchAll(key))
            }
      }
      return result
   }

   /// Find the elements immediately preceeding and immediately following
   /// `key`, only if `key` itself is in the tree or else returns `nil`.
   /// Returns the rightmost element to the left of `key` and the leftmost
   /// element to the right of `key`.
   public func neighboursOf(_ key: K) -> (R?,R?)? {
      guard contains(key) else { return nil }
      return neighboursFor(key)
   }
   
   /// Find the records which would immediately preceed and follow `key`, whether
   /// or not `key` itself is in the tree. Returns the rightmost record to the
   /// left of `key` and the leftmost record to the right of `key`.
   /// Duplicate keys are not neighbours.
   public func neighboursFor(_ key: K, leftRecord: R? = nil, rightRecord: R? = nil) -> (R?,R?) {
      switch self {
         case .empty:
            return (leftRecord, rightRecord)
         case let .node(record, left, right):
            switch (key ⊰ record.redBlackTreeKey, K.duplicatesAllowed) {
               case (.matching, false): return (left.last ?? leftRecord, right.first ?? rightRecord)
               case (.matching, true):
                  // search further to eliminate duplicates left and right
                  var l,r: R?
                  if left.contains(key) { // look deeper
                     l = left.neighboursFor(key, leftRecord: leftRecord, rightRecord: record).0
                  } else { l = left.last ?? leftRecord }
                  if right.contains(key) {
                     r = right.neighboursFor(key, leftRecord: record, rightRecord: rightRecord).1
                  } else { r = right.first ?? rightRecord }
                  return (l,r)
               case (.leftTree, _): return left.neighboursFor(key, leftRecord: leftRecord, rightRecord: record)
               case (.rightTree, _): return right.neighboursFor(key, leftRecord: record, rightRecord: rightRecord)
            }
      }
   }
}

//MARK: - Utilities
extension BinaryTree {
   public var isEmpty: Bool {
      switch self {
         case .empty: return true
         default: return false
      }
   }
   
   /// Fetch the first element in a `BinaryTree`.
   /// Returns leftmost record or nil if the tree is empty. Tree is unchanged.
   public var first: R? {
      switch self {
         case .empty:
            return nil
         case let .node(record, left, _):
            if left.first == nil { return record }
            return left.first
      }
   }
   
   /// Fetch the last element in a `BinaryTree`.
   /// Returns rightmost record or nil if the tree is empty. Tree is unchanged.
   public var last: R? {
      switch self {
         case .empty:
            return nil
         case let .node(record, _, right):
            if right.last == nil { return record }
            return right.last
      }
   }
   
   /// Counts records in a `BinaryTree`.
   /// Tree is unchanged.
   public var count: Int {
      switch self {
         case .empty:
            return 0
         case let .node(_, left, right):
            return left.count + 1 + right.count
      }
   }
   
   /// Measures the longest path from root to leaf in a `BinaryTree`.
   /// Tree is unchanged.
   public var height: Int {
      switch self {
         case .empty:
            return 0
         case let .node(_, left, right):
            return 1 + max(left.height, right.height)
      }
   }
}

//MARK: - CustomStringConvertible Conformance
/// Produces graphic description of a `BinaryTree`
extension BinaryTree: CustomStringConvertible {
   private func diagram(_ top: String = "",
                        _ centre: String = "",
                        _ bottom: String = "") -> String {
      switch self {
         case .empty:
            return centre + "◦\n"
         case let .node(record, .empty, .empty):
            return centre + "◻︎\(record)\n"
         case let .node(record, left, right):
            return left.diagram(top + "    ", top + "┌───", top + "│   ")
            + centre + "◻︎\(record)\n"
            + right.diagram(bottom + "│   ", bottom + "└───", bottom + "    ")
      }
   }
   
   public var description: String {
      return diagram()
   }
}

//MARK: - Insertion
extension BinaryTree {
   /// Inserts an array of elements into a `BinaryTree`.
   ///
   /// Elements are sorted in the tree according to the rule used by the ⊰
   /// operator in the `BinaryTreeKeyProtocol` which produces an
   /// implicit sort key. Elements which obtain duplicate keys using this
   /// operator will be excluded from the tree and returned in an array
   /// unless the `duplicatesAllowed` flag in the `BinaryTreeOrderingProtocol`
   /// is set to true. When permitted, duplicates are added to the tree in the
   /// order in which they were included in the input array as determined
   /// by the `duplicatesUseFIFO` flag on the key.
   ///
   /// - Parameter array: An array containing records to be inserted in the tree.
   /// - Returns: An array containing only those records which failed to
   ///   be inserted in the tree because records with the same keys were
   ///   already in the tree and the `duplicatesAllowed` flag was set to false.
   /// - Complexity: O(*m*log*n*) _base 2_, where *n* is the number of elements
   ///   already in the tree and *m* is the size of `array`.
   @discardableResult
   public mutating func insert(_ array:[R]) -> [R] {
      var fails = [R]()
      for record in array {
         let success = self.insert(record)
         if !success { fails.append(record) }
      }
      return fails
   }
   
   /// Inserts an element into a BinaryTree.
   ///
   /// Elements are placed in the tree in a location determined by the ⊰
   /// operator in the `BinaryTreeOrderingProtocol` which produces an
   /// implicit sort key. An element which obtains a key which matches an
   /// element already in the tree will be excluded from the tree unless
   /// the `duplicatesAllowed` flag in the `BinaryTreeOrderingProtocol`
   /// is set to true. When permitted, duplicates are sorted in the order
   /// in which they were added to the tree.
   ///
   /// - Parameter array: An array containing elements to be inserted in the tree.
   /// - Returns: `true` if the element is successfully inserted in the tree.
   /// - Complexity: O(log*n*) _base 2_, where *n* is the number of elements
   ///   already in the tree.
   @discardableResult
   public mutating func insert(_ element: R) -> Bool {
      let (tree, old) = recursiveInsert(element)
      switch tree {
         case .empty: return false
         case let .node(record, left, right):
            self = .node(record, left, right)
      }
      return old == nil
   }

   /// Recursive helper function for insert(element) which should
   /// not be called directly.
   private func recursiveInsert(_ element: R) -> (tree: BinaryTree, old: R?) {
      switch self {
         case .empty:
            return (.node(element, .empty, .empty), nil)
         case let .node(record, left, right):
            switch (element.redBlackTreeKey ⊰ record.redBlackTreeKey, K.duplicatesAllowed, K.duplicatesUseFIFO) {
               case (.matching, false, _):
                  return (self, record)
               case (.matching, true, false),(.leftTree, _, _):
                  let (l, old) = left.recursiveInsert(element)
                  if let old = old { return (self, old) }
                  return (BinaryTree<R,K>.node(record, l, right), old)
               case (.matching, true, true),(.rightTree, _, _):
                  let (r, old) = right.recursiveInsert(element)
                  if let old = old { return (self, old) }
                  return (BinaryTree<R,K>.node(record, left, r), old)
            }
      }
   }
}

//MARK: - Removal
extension BinaryTree {
   /// Removes first record found containing key
   ///
   /// See also: `removeAll() -> [R]`
   /// - Parameter key: key part of desired record
   /// - Returns: removed record or nil if none found.
   @discardableResult
   public mutating func remove(_ key: K) -> R? {
      let search = recursiveRemove(key)
      if search.removed != nil { self = search.tree }
      return search.removed
   }

   /// Removes all records containing key
   ///
   /// See also: `remove() -> R?`
   /// - Parameter key: key part of desired record
   /// - Returns: array containing removed records. Empty if none found.
   @discardableResult
   public mutating func removeAll(_ key: K) -> [R] {
      var list = [R]()
      var record = remove(key)
      while record != nil {
         list.append(record!)
         record = remove(key)
      }
      return list
   }
   
   private func recursiveRemove(_ key: K) -> (tree: BinaryTree<R,K>, removed: R?) {
      switch self {
         case .empty:
            return (self, nil)
         case let .node(record, _, _):
            switch (key ⊰ record.redBlackTreeKey, K.duplicatesAllowed, K.duplicatesUseFIFO) {
               case (.matching, false, _):    // found it!!
                  let s = self.replace()
                  return (s, record)
               case (.matching, true, let usesFIFO):    // found it!!
                  var e:(tree: BinaryTree<R,K>, deleted: R?)
                  if usesFIFO { e = self.leftDelete(key) }
                  else { e = self.rightDelete(key) }
                  if e.deleted == nil {
                     let s = self.replace()
                     return (s, record)
                  } else {
                     return (e.tree, e.deleted)
                  }
               case (.leftTree, _, _):      // Still looking (left)
                  let s = self.leftDelete(key)
                  return (s.tree, s.deleted)
               case (.rightTree, _, _):     // Still looking (right)
                  let s = self.rightDelete(key)
                  return (s.tree, s.deleted)
            }
      }
   }
   
   private func replace() -> BinaryTree<R,K> {
      switch self {
         case let .node(_, left, right):
            return left.fused(right)
         default: return self
      }
   }
   
   private func leftDelete(_ key: K) -> (tree: BinaryTree<R,K>, deleted: R?) {
      switch self {
         case .empty:
            return (self, nil)
         case let .node(record, left, right):
            let s = left.recursiveRemove(key)
            return (BinaryTree<R,K>.node(record, s.tree, right), s.removed)
      }
   }
   
   private func rightDelete(_ key: K) -> (tree: BinaryTree<R,K>, deleted: R?) {
      switch self {
         case .empty:
            return (self, nil)
         case let .node(record, left, right):
            let s = right.recursiveRemove(key)
            return (BinaryTree<R,K>.node(record, left, s.tree), s.removed)
      }
   }
}

//MARK: - Private Insertion/Deletion Helpers
extension BinaryTree {
   private func fused(_ with: BinaryTree<R,K>) -> BinaryTree<R,K> {
      switch (self, with) {
         case (.empty,.empty):
            return .empty
         case let (t1,.empty), let (.empty,t1):
            return t1
         case let (.node(x, t1, t2),.node(y, t3, t4)):
            let s = t2.fused(t3)
            switch s {
               case let .node(z, s1, s2):
                  return BinaryTree<R,K>.node(z, .node(x,t1,s1), .node(y,s2,t4))
               default:
                  return .empty
            }
      }
   }
}

extension BinaryTree {
   public func map<T>(_ transform:(R) -> T) -> [T] {
      switch self {
         case .empty: return [T]()
         case let .node(record, left, right):
            return left.map(transform) + [transform(record)] + right.map(transform)
      }
   }
}

//MARK: - ENUMs
/// Operator to choose ordering on `BinaryTree`
infix operator ⊰: ComparisonPrecedence

// ENUMs
/// Results returned from a comparison using the ⊰ operator
///
/// Case values available are:
/// - .matching: matches this sub-tree
/// - .leftTree: belongs in the left sub-tree
/// - .rightTree: belongs in the right sub-tree
public enum BinaryTreeComparator {
   case matching
   case leftTree
   case rightTree
}

