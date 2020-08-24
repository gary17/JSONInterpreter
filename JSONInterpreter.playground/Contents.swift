import Foundation

enum Failure: Error, LocalizedError
{
	case unknown, httpError(code: Int?, message: String?), emptyResponse
		
	var errorDescription: String? // converts to .localizedDescription
	{
		switch self
		{
			// TODO: internationalization

			case .unknown:
				return "unknown network request failure"
			
			case .httpError(let code, let message):
				return
					"HTTP request failure, " +
					"error code: [\(code != nil ? String(code ?? 0) : "unknown")], " +
					"message: [\(message != nil ? String(message ?? "") : "none")]"
					
			case .emptyResponse:
				return "no data returned"
		}
	}
}

// "JSONPlaceholder is a free online REST API that you can use whenever you need some fake data."
let endpointURL = "https://jsonplaceholder.typicode.com/todos/1"

var request = URLRequest(url: URL(string: endpointURL)!)
let task = URLSession.shared.dataTask(with: request) { data, response, error in
	
	guard error == nil else
	{
		// fundamental networking errors
		_ = data

		fatalError((error ?? Failure.unknown)
			.localizedDescription)
	}

	guard let httpStatus = response as? HTTPURLResponse, (200 ... 299).contains(httpStatus.statusCode) else
	{
		// http errors
		_ = data

		fatalError(Failure.httpError(
			code: (response as? HTTPURLResponse)?.statusCode, message: String(describing: response))
				.localizedDescription)
	}

	guard let data = data, data.count > 0 else
	{
		// bus errors
		
		fatalError(Failure.emptyResponse
			.localizedDescription)
	}
	
	/*
	
	{
		"userId": 1,
		"id": 1,
		"title": "delectus aut autem",
		"completed": false
	}

	*/

	let root: JSONInterpreter.Dictionary

	do
	{
		let json = try JSONSerialization.jsonObject(with: data)
		root = try JSONInterpreter.interpret(json) as JSONInterpreter.Dictionary
	}
	catch
	{
		fatalError(error
			.localizedDescription)
	}

	do
	{
		// extract a JSON element of a particular type
		
		_ = try JSONInterpreter.interpret("userId", in: root) as UInt
		_ = try JSONInterpreter.interpret("title", in: root) as String
	}
	catch
	{
		fatalError(error
			.localizedDescription)
	}

	do
	{
		// extract an optional JSON element that is a container (an array, a dictionary, ...)
		
		if JSONInterpreter.have("subarray", in: root)
		{
			let subarray = try JSONInterpreter.interpret("subarray", in: root) as JSONInterpreter.Array
			
			for _ in subarray
			{
				// ...
			}
		}
	}
	catch
	{
		fatalError(error
			.localizedDescription)
	}

	do
	{
		// extract a JSON element with closure-based validation

		_ = try JSONInterpreter.interpret("id", in: root) { (value: UInt) in
			
			// WARNING: returning nil induces JSONInterpreter.InterpretationError.unreadable(<key>)
			(1 ... 99).contains(value) ? value : nil
		}
	}
	catch
	{
		fatalError(error
			.localizedDescription)
	}

	do
	{
		// extract a JSON element with closure-based construction of another type (e.g., String -> URL)
		
		if JSONInterpreter.have("thumb", in: root)
		{
			// WARNING: a failable initializer returning nil induces JSONInterpreter.InterpretationError.unreadable(<key>)
			_ = try JSONInterpreter.interpret("thumb", in: root) { (value: String) in URL(string: value) }
		}
	}
	catch
	{
		fatalError(error
			.localizedDescription)
	}
}

task.resume()
