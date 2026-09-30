package org.oaef.kmp

class Greeting {
    fun greet(recipientName: String): String {
        require(recipientName.isNotBlank()) { "Recipient name must not be blank" }
        return "Hello, $recipientName! Welcome to Kotlin Multiplatform."
    }
}
