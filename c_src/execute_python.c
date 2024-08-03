#include <Python.h>
#include <stdio.h>
#include <stdlib.h>

char* execute_python(const char *input_value)
{
    PyObject *pName, *pModule, *pFunc, *pArgs, *pValue, *pStrValue, *pSysPath, *pPath;
    char *result = NULL;
    char *cangchain_home;

    // 初始化Python解释器
    Py_Initialize();

    // 检查初始化是否成功
    if (!Py_IsInitialized()) {
        fprintf(stderr, "Failed to initialize Python interpreter\n");
        Py_Finalize();
        return NULL;
    }

    // 获取环境变量 CANGCHAIN_HOME
    cangchain_home = getenv("CANGCHAIN_HOME");
    if (!cangchain_home) {
        fprintf(stderr, "CANGCHAIN_HOME environment variable is not set\n");
        Py_Finalize();
        return NULL;
    }

    // 添加模块所在目录到 sys.path
    pSysPath = PySys_GetObject("path");
    pPath = PyUnicode_FromString(cangchain_home);
    PyList_Append(pSysPath, pPath);
    Py_DECREF(pPath);

    // 导入Python模块
    pName = PyUnicode_FromString("temp");
    pModule = PyImport_Import(pName);
    Py_DECREF(pName);

    if (pModule != NULL) {
        // 获取函数
        pFunc = PyObject_GetAttrString(pModule, "main");
        if (pFunc && PyCallable_Check(pFunc)) {
            // 准备传入函数的参数
            pArgs = PyTuple_New(1);
            PyTuple_SetItem(pArgs, 0, PyUnicode_FromString(input_value));

            // 调用函数
            pValue = PyObject_CallObject(pFunc, pArgs);
            Py_DECREF(pArgs);

            if (pValue != NULL) {
                // 将返回值转换为字符串
                pStrValue = PyObject_Str(pValue);
                if (pStrValue != NULL) {
                    PyObject* temp_bytes = PyUnicode_AsEncodedString(pStrValue, "UTF-8", "strict");
                    if (temp_bytes != NULL) {
                        result = strdup(PyBytes_AS_STRING(temp_bytes));
                        Py_DECREF(temp_bytes);
                    }
                    Py_DECREF(pStrValue);
                }
                Py_DECREF(pValue);
            } else {
                PyErr_Print();
                fprintf(stderr, "Function call failed\n");
            }
        } else {
            if (PyErr_Occurred())
                PyErr_Print();
            fprintf(stderr, "Cannot find function 'main'\n");
        }
        Py_XDECREF(pFunc);
        Py_DECREF(pModule);
    } else {
        PyErr_Print();
        fprintf(stderr, "Failed to load \"temp\"\n");
    }

    // 清理Python解释器
    Py_Finalize();

    return result; // 返回转换后的字符串
}
