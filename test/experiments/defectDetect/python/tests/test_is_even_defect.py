import unittest

def is_even(n):
    return n % 2 == 0

class TestIsEven(unittest.TestCase):
    def test_positive_even(self):
        self.assertTrue(is_even(4))

    def test_positive_odd(self):
        self.assertFalse(is_even(3))

    def test_negative_even(self):
        self.assertTrue(is_even(-2))

    def test_negative_odd(self):
        self.assertFalse(is_even(-1))

    def test_zero(self):
        self.assertTrue(is_even(0))

    def test_float_input(self):
        with self.assertRaises(TypeError):
            is_even(2.5)

    def test_string_input(self):
        with self.assertRaises(TypeError):
            is_even("2")

    def test_none_input(self):
        with self.assertRaises(TypeError):
            is_even(None)

if __name__ == '__main__':
    unittest.main()