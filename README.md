# Backend Experiments in Swift

First you need to create a CouchDB database in your local machine.

After that, replace your CouchDB database credentials with current ones in [SwiftBackend.swift](https://github.com/candostdagdeviren/SwiftBackend/blob/master/Sources/SwiftBackendLib/SwiftBackend.swift#L9) file.

Don't forget to change `dbName` parameter at the same file in line 21.

Keep you database open.

To build the project run 

```swift
swift build
```

This will build the app and to run the app use

```swift
./.build/debug/SwiftBackendApp
```

or 

```
docker run -p 8090:8090 swiftbackend
```

to run the tests use command

`swift test`

That's it!
