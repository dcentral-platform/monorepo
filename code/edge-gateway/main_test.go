package main

import "testing"

func TestProcessEvent(t *testing.T) {
	result := ProcessEvent("test-event")
	expected := "Processed: test-event"
	if result != expected {
		t.Errorf("ProcessEvent() = %v, want %v", result, expected)
	}
}