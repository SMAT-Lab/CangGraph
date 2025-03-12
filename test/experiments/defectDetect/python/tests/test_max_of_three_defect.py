import unittest

def max_of_three(a, b, c):
    return max(a, b, c)

class TestMaxOfThree(unittest.TestCase):
    def test_max_of_three(self):
        # Test with positive integers
        self.assertEqual(max_of_three(1, 2, 3), 3)
        self.assertEqual(max_of_three(3, 2, 1), 3)
        self.assertEqual(max_of_three(2, 3, 1), 3)

        # Test with negative integers
        self.assertEqual(max_of_three(-1, -2, -3), -1)
        self.assertEqual(max_of_three(-3, -2, -1), -1)
        self.assertEqual(max_of_three(-2, -3, -1), -1)

        # Test with mixed positive and negative integers
        self.assertEqual(max_of_three(-1, 2, 3), 3)
        self.assertEqual(max_of_three(3, -2, 1), 3)
        self.assertEqual(max_of_three(2, -3, -1), 2)

        # Test with floating point numbers
        self.assertEqual(max_of_three(1.1, 2.2, 3.3), 3.3)
        self.assertEqual(max_of_three(3.3, 2.2, 1.1), 3.3)
        self.assertEqual(max_of_three(2.2, 3.3, 1.1), 3.3)

        # Test with mixed integers and floating point numbers
        self.assertEqual(max_of_three(1, 2.2, 3), 3)
        self.assertEqual(max_of_three(3, 2.2, 1.1), 3)
        self.assertEqual(max_of_three(2.2, 3, 1.1), 3)

        # Test with non-numeric inputs (potential defect)
        # with self.assertRaises(TypeError):
        #     max_of_three('a', 'b', 'c')
        # with self.assertRaises(TypeError):
        #     max_of_three(1, 'b', 3)
        # with self.assertRaises(TypeError):
        #     max_of_three(1, 2, 'c')

        # Test with None values (potential defect)
        with self.assertRaises(TypeError):
            max_of_three(None, 2, 3)
        with self.assertRaises(TypeError):
            max_of_three(1, None, 3)
        with self.assertRaises(TypeError):
            max_of_three(1, 2, None)

if __name__ == '__main__':
    unittest.main()