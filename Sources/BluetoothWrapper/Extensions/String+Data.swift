
extension String {
  
  /// Create `Data` from hexadecimal string representation
  ///
  /// This creates a `Data` object from hex string. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
  ///
  /// - returns: Data represented by this hexadecimal string.
  
  var hexadecimal: Data? {
    var data = Data(capacity: self.count / 2)
    
    let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
    regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
      let byteString = (self as NSString).substring(with: match!.range)
      let num = UInt8(byteString, radix: 16)!
      data.append(num)
    }
    
    guard data.count > 0 else { return nil }
    
    return data
  }
  
}

extension Data {
  var bytesCount: String {
    String(format: "%02X", count)
  }
  
  var bytes: String {
    self.reduce("") {$0 + String(format: "%02x", $1)}
  }
  
  var binary: (ClosedRange<Int>) -> String {
    { range in
      String(uInt16, radix: 2).pad(with: "0", toLength: 16).substring(with: range)
    }
  }
  
  var uInt16: UInt16 {
    UInt16(bytes, radix: 16) ?? 0
  }
}

extension String {
  func pad(with character: String, toLength length: Int, toEnd: Bool = false) -> String {
    let padCount = length - self.count
    guard padCount > 0 else { return self }
    
    if !toEnd {
      return String(repeating: character, count: padCount) + self
    } else {
      return self + String(repeating: character, count: padCount)
    }
  }
}

extension Data {
  subscript(safe index: Index) -> Element? {
      get { return self.indices.contains(index) ? self[index] : nil }
  }
  
  func subdata(in range: PartialRangeFrom<Int>) -> Data {
    return subdata(in: range.lowerBound ... (count - 1))
  }
  
  func subdata(in range: PartialRangeThrough<Int>) -> Data {
    return subdata(in: 0 ..< range.upperBound + 1)
  }
  
  func subdata(in range: ClosedRange<Index>) -> Data {
    return subdata(in: range.lowerBound ..< range.upperBound + 1)
  }
  
  var uint16: UInt16 {
    withUnsafeBytes { $0.load(as: UInt16.self) }
  }
}

extension String {
  
  public subscript(range: PartialRangeFrom<Int>) -> String {
    return substring(from: range.lowerBound)
  }

    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
  
  func substring(with r: ClosedRange<Int>) -> String {
      let startIndex = index(from: r.lowerBound)
      let endIndex = index(from: r.upperBound)
      return String(self[startIndex..<endIndex])
  }
}
