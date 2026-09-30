package org.oaef.kmp

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class GreetingTest {
    private val greetingService = Greeting()

    @Test
    fun testGreetingWithValidName() {
        val result = greetingService.greet("Developer")
        assertEquals("Hello, Developer! Welcome to Kotlin Multiplatform.", result)
    }

    @Test
    fun testGreetingWithBlankNameThrowsException() {
        assertFailsWith<IllegalArgumentException> {
            greetingService.greet("   ")
        }
    }
}
