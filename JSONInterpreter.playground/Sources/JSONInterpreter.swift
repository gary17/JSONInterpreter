//
//  JSONInterpreter.swift
//  JSONInterpreter
//
//  Created by User on 8/24/20.
//  Copyright © R&F Consulting, Inc. All rights reserved.
//

import Foundation

public enum /* namespace */ JSONInterpreter {
	// unit-of-storage abstractions
	
	public typealias Key = String 	// JSON keys are always strings
	public typealias Dictionary = [Key : Any] // could be [AnyHashable : Any]
	public typealias Array = [Any]

	// failure points

	public enum InterpretationError: LocalizedError {
		case syntax(Error)
		case malformed

		case missing(Key)
		case wrongType(Key)
		case unreadable(Key)
		
		public var errorDescription: String? { // converts to .localizedDescription
			switch self {
				// TODO: internationalization

				case .syntax:
					return "invalid JSON syntax"
				
				case .malformed:
					return "unexpected JSON structure"
				
				case .missing(let key):
					return "missing JSON [\(key)]"
				
				case .wrongType(let key):
					return "wrongly typed JSON [\(key)]"
				
				case .unreadable(let key):
					return "unreadable JSON [\(key)]"
			}
		}
	}

	// interpreters

	public static func interpret<T>(
			_ root: Any) throws -> T {
		guard let raw = root as? T else { throw InterpretationError.malformed }

		return raw
	}

	public static func have(
			_ key: JSONInterpreter.Key, in dictionary: JSONInterpreter.Dictionary) -> Bool {
		return dictionary[key] != nil
	}
	
	public static func interpret<T>(
			_ key: JSONInterpreter.Key, in dictionary: JSONInterpreter.Dictionary) throws -> T {
		guard let abstract = dictionary[key] else { throw InterpretationError.missing(key) }
		guard let raw = abstract as? T else { throw InterpretationError.wrongType(key) }

		return raw
	}

	// a converter takes an instance of one type and returns another; returning nil induces failure
	// FYI: using nil to indicate failure (as opposed to a throwing converter) allows for convenient failable initializer usage
	//
	public typealias Converter<T, U> = (T) -> U?

	public static func interpret<T, U>(
			_ key: JSONInterpreter.Key, in dictionary: JSONInterpreter.Dictionary,
				using converter: Converter<T, U>) throws -> U {
		let raw = try interpret(key, in: dictionary) as T
		
		// WARNING: returning nil from a converter induces JSONInterpreter.InterpretationError.unreadable(<key>)
		guard let value = converter(raw) else { throw InterpretationError.unreadable(key) }
		
		return value
	}
}
