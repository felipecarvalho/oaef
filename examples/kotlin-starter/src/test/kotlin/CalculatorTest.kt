package org.oaef.kotlin

import kotlin.test.Test
import kotlin.test.assertEquals

class CalculatorTest {
    private val calculator = Calculator()

    @Test
    fun testAddReturnsSum() {
        val result = calculator.add(4, 5)
        assertEquals(9, result)
    }

    @Test
    fun testMultiplyReturnsProduct() {
        val result = calculator.multiply(3, 7)
        assertEquals(21, result)
    }
}
