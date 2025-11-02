import Foundation

/// Base58 encoding/decoding (Bitcoin-style, used by Solana)
public struct Base58 {
    private static let alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    private static let alphabetBytes = [UInt8](alphabet.utf8)
    
    public static func encode(_ data: Data) -> String {
        guard !data.isEmpty else { return "" }
        
        var num = BigUInt(data)
        var result: [UInt8] = []
        
        while num > 0 {
            let remainder = num % 58
            result.append(alphabetBytes[Int(remainder)])
            num /= 58
        }
        
        // Add leading zeros
        for byte in data {
            if byte == 0 {
                result.append(alphabetBytes[0])
            } else {
                break
            }
        }
        
        return String(bytes: result.reversed(), encoding: .utf8) ?? ""
    }
    
    public static func decode(_ string: String) -> Data? {
        guard !string.isEmpty else { return Data() }
        
        var num = BigUInt.zero
        for char in string {
            guard let index = alphabet.firstIndex(of: char) else {
                return nil
            }
            let charIndex = alphabet.distance(from: alphabet.startIndex, to: index)
            let charValue = BigUInt(Data([UInt8(charIndex)]))
            num = num * 58 + charValue
        }
        
        var data = num.serialize()
        
        // Handle leading zeros
        for char in string {
            if char == alphabet.first {
                data.insert(0, at: 0)
            } else {
                break
            }
        }
        
        return Data(data)
    }
}

// Simple BigUInt implementation for Base58
struct BigUInt {
    private var digits: [UInt64] = []
    
    static var zero: BigUInt { BigUInt(Data([0])) }
    
    init(_ data: Data) {
        var bytes = [UInt8](data)
        bytes.reverse()
        
        var value: UInt64 = 0
        var shift: UInt = 0
        
        for byte in bytes {
            value |= UInt64(byte) << shift
            shift += 8
            
            if shift == 64 {
                digits.append(value)
                value = 0
                shift = 0
            }
        }
        
        if value > 0 || digits.isEmpty {
            digits.append(value)
        }
        
        normalize()
    }
    
    private mutating func normalize() {
        while digits.count > 1 && digits.last == 0 {
            digits.removeLast()
        }
    }
    
    func serialize() -> [UInt8] {
        guard !digits.isEmpty else { return [0] }
        
        var bytes: [UInt8] = []
        for digit in digits {
            var d = digit
            for _ in 0..<8 {
                bytes.append(UInt8(d & 0xFF))
                d >>= 8
            }
        }
        
        // Remove trailing zeros
        while let last = bytes.last, last == 0 {
            bytes.removeLast()
        }
        
        bytes.reverse()
        return bytes.isEmpty ? [0] : bytes
    }
    
    static func + (lhs: BigUInt, rhs: BigUInt) -> BigUInt {
        var result = lhs
        var carry: UInt64 = 0
        let maxDigits = max(lhs.digits.count, rhs.digits.count)
        
        while result.digits.count < maxDigits {
            result.digits.append(0)
        }
        
        for i in 0..<maxDigits {
            let lhsDigit = i < lhs.digits.count ? lhs.digits[i] : 0
            let rhsDigit = i < rhs.digits.count ? rhs.digits[i] : 0
            let sum = lhsDigit + rhsDigit + carry
            result.digits[i] = sum & 0xFFFFFFFFFFFFFFFF
            carry = sum >> 64
        }
        
        if carry > 0 {
            result.digits.append(carry)
        }
        
        result.normalize()
        return result
    }
    
    static func * (lhs: BigUInt, rhs: Int) -> BigUInt {
        var result = BigUInt(Data([0]))
        var carry: UInt64 = 0
        
        for digit in lhs.digits {
            let product = digit * UInt64(rhs) + carry
            result.digits.append(product & 0xFFFFFFFFFFFFFFFF)
            carry = product >> 64
        }
        
        if carry > 0 {
            result.digits.append(carry)
        }
        
        result.normalize()
        return result
    }
    
    static func % (lhs: BigUInt, rhs: Int) -> Int {
        var remainder: UInt64 = 0
        for digit in lhs.digits.reversed() {
            remainder = (remainder * (1 << 32) * (1 << 32) + digit) % UInt64(rhs)
        }
        return Int(remainder)
    }
    
    static func /= (lhs: inout BigUInt, rhs: Int) {
        var carry: UInt64 = 0
        let rhs64 = UInt64(rhs)
        
        for i in (0..<lhs.digits.count).reversed() {
            let dividend = carry * (1 << 32) * (1 << 32) + lhs.digits[i]
            lhs.digits[i] = dividend / rhs64
            carry = dividend % rhs64
        }
        
        lhs.normalize()
    }
    
    static func > (lhs: BigUInt, rhs: Int) -> Bool {
        if lhs.digits.count > 1 { return true }
        if lhs.digits.isEmpty { return false }
        return lhs.digits[0] > UInt64(rhs)
    }
}

