import unittest

def add(a, b):
    return a + b

class TestAddFunction(unittest.TestCase):
    def test_add_integers(self):
        # Test case for adding two integers
        self.assertEqual(add(2, 3), 5)

    def test_add_floats(self):
        # Test case for adding two floats
        self.assertEqual(add(2.5, 3.5), 6.0)

    def test_add_strings(self):
        # Test case for adding two strings (potential defect: concatenation instead of numeric addition)
        self.assertEqual(add("2", "3"), "23")

    def test_add_mixed_types(self):
        # Test case for adding mixed types (potential defect: TypeError)
        with self.assertRaises(TypeError):
            add(2, "3")

    def test_add_large_numbers(self):
        # Test case for adding large numbers (potential defect: overflow in some languages, but Python handles it)
        self.assertEqual(add(1e308, 1e308), 2e308)

    def test_add_negative_numbers(self):
        # Test case for adding negative numbers
        self.assertEqual(add(-2, -3), -5)

    def test_add_zero(self):
        # Test case for adding zero
        self.assertEqual(add(0, 5), 5)
        self.assertEqual(add(5, 0), 5)

if __name__ == "__main__":
    unittest.main()