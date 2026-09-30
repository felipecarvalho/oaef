package main

import "testing"

func TestAdd(t *testing.T) {
	if Add(2, 3) != 5 {
		t.Errorf("expected 5")
	}
}

func TestMultiply(t *testing.T) {
	if Multiply(3, 4) != 12 {
		t.Errorf("expected 12")
	}
}
