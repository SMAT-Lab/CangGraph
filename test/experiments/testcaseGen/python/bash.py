import unittest

def run_tests_in_directory(directory):
    loader = unittest.TestLoader()
    suite = loader.discover(directory, pattern="test_*.py")
    runner = unittest.TextTestRunner(verbosity=2)
    runner.run(suite)

if __name__ == "__main__":
    directory = "test/experiments/testcaseGen/python/tests"
    run_tests_in_directory(directory)