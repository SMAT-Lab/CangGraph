package onnx

@C
struct CXDArray {
    var data: CPointer<Unit> = CPointer<Unit>()
    var nDim: Int64 = 0
    var shape: CPointer<Int64> = CPointer<Int64>()
}

public interface IDArray <: ToString {
    func getData(): CPointer<Unit>
    func getShapeDims(): Int64
    func getShapePtr(): CPointer<Int64>
}

public class XDArray<T> <: IDArray where T <: CType & XCtype & ToString {
    let data: CPointer<T>
    let base: Option<XDArray<T>>
    let shape_: Array<Int64>
    let strides_: Array<Int64>
    let compactMem: Bool
    let shapePtr_: CPointerHandle<Int64>
    let stridesPtr_: CPointerHandle<Int64>

    public prop shape: Array<Int64> {
        get() { shape_.clone() }
    }

    public prop strides: Array<Int64> {
        get() { shape_.clone() }
    }

    public prop size: Int64 {
        get() { ShapeMul(this.shape_, scalarMode: true) }
    }

    prop shapePtr: CPointer<Int64> {
        get() { shapePtr_.pointer }
    }

    prop stridesPtr: CPointer<Int64> {
        get() { stridesPtr_.pointer }
    }

    init(data: CPointer<T>, shape: Array<Int64>) {
        this.data = data
        this.shape_ = shape.clone()
        this.strides_ = Array<Int64>(this.shape_.size, item:1)
        for (i in (this.strides_.size-2)..-1:-1) {
            this.strides_[i] = this.strides_[i+1]*this.shape_[i+1]
        }
        this.base = None
        this.compactMem = true
        this.shapePtr_ = unsafe { acquireArrayRawData(this.shape_) }
        this.stridesPtr_ = unsafe { acquireArrayRawData(this.strides_) }
    }

    public init(value: Array<T>, shape!: Array<Int64>) {
        if (shape.size <= 0 || !IsPositive(shape)) {
            throw IllegalArgumentException("XDArray init with invalid shape: ${shape}")
        }
        if (value.size != ShapeMul(shape)) {
            throw IllegalArgumentException("XDArray init failed: size of input Array doesn't math input shape")
        }

        this.shape_ = shape.clone()
        this.strides_ = Array<Int64>(this.shape_.size, item:1)
        for (i in (this.strides_.size-2)..-1:-1) {
            this.strides_[i] = this.strides_[i+1]*this.shape_[i+1]
        }
        this.data = value.toCPointer()
        this.base = None
        this.compactMem = true
        this.shapePtr_ = unsafe { acquireArrayRawData(this.shape_) }
        this.stridesPtr_ = unsafe { acquireArrayRawData(this.strides_) }
    }



    public init(value: ArrayList<T>) {
        this.base = None
        this.compactMem = true
        this.shape_ = [value.size]
        this.strides_ = [1]
        this.data = value.toArray().toCPointer()
        this.shapePtr_ = unsafe { acquireArrayRawData(this.shape_) }
        this.stridesPtr_ = unsafe {acquireArrayRawData(this.strides_) }
    }
    
    public init(value: Array<T>) {
        this.base = None
        this.compactMem = true
        this.shape_ = [value.size]
        this.strides_ = [1]
        this.data = value.toCPointer()
        this.shapePtr_ = unsafe { acquireArrayRawData(this.shape_) }
        this.stridesPtr_ = unsafe {acquireArrayRawData(this.strides_) }
    }

    public init(value: Array<Array<T>>) {
        if (value.size == 0) {
            throw IllegalArgumentException("XDArray init failed sizeof input Array is empty")
        }
        let size1 = value[0].size
        if (size1 == 0) {
            throw IllegalArgumentException("XDArray init failed sizeof input Array is empty")
        }
        var t_data = Array<T>(value.size*size1, item: value[0][0])
        var startOffset = 0
        for (v in value) {
            if (size1 != v.size) {
                throw IllegalArgumentException("XDArra init failed: input Array size is not compatible")
            }
            v.copyTo(t_data, 0, startOffset, size1)
            startOffset += size1
        }
        this.base = None
        this.compactMem = true
        this.shape_ = [value.size, size1]
        this.strides_ = [size1, 1]
        this.data = t_data.toCPointer()
        this.shapePtr_ = unsafe { acquireArrayRawData(this.shape_) }
        this.stridesPtr_ = unsafe { acquireArrayRawData(this.strides_) }
    }

    public init(value: Array<Array<Array<T>>>) {
        if (value.size == 0) {
            throw IllegalArgumentException("XDArray init failed sizeof input Array is empty")
        }
        let size1 = value[0].size
        if (size1 == 0) {
            throw IllegalArgumentException("XDArray init failed sizeof input Array is empty")
        }
        let size2 = value[0][0].size
        if (size1 == 0) {
            throw IllegalArgumentException("XDArray init failed sizeof input Array is empty")
        }
        var t_data = Array<T>(value.size*size1*size2, item: value[0][0][0])
        var startOffset = 0
        for (v1 in value) {
            if (size1 != v1.size) {
                throw IllegalArgumentException("XDArra init failed: input Array size is not compatible")
            }
            for (v2 in v1) {
                if (size2 != v2.size) {
                    throw IllegalArgumentException("XDArra init failed: input Array size is not compatible")
                }
                v2.copyTo(t_data, 0, startOffset, size2)
                startOffset += size2
            }
        }
        this.base = None
        this.compactMem = true
        this.shape_ = [value.size, size1, size2]
        this.strides_ = [size1*size2, size2, 1]
        this.data = t_data.toCPointer()
        this.shapePtr_ = unsafe { acquireArrayRawData(this.shape_) }
        this.stridesPtr_ = unsafe { acquireArrayRawData(this.strides_) }
    }

    public func getData(): CPointer<Unit> {
        return CPointer<Unit>(this.data)
    }
    public func getShapeDims(): Int64 {
        return this.shape_.size
    }
    public func getShapePtr(): CPointer<Int64> {
        return shapePtr_.pointer
    }
    public func isCompactMem(): Bool {
        return compactMem
    }

    public func toArray(): Array<T> {
        if (this.size == 0) {
            return Array<T>()
        }
        if (compactMem) {
            return Array<T>(this.size, { i => unsafe { data.read(i) } })
        } else {
            throw Exception("XDArray::toArray not support now")
        }
    }

    operator func [](index: ArrayList<Int64>): T {
        let i = index.toArray()
        return this[i]
    }

    operator func [](index: ArrayList<Int64>, value!: T): Unit {
        let i = index.toArray()
        this[i] = value
    }

    public operator func[](index: Array<Int64>): T {
        if (index.size != this.shape_.size) {
            throw IllegalArgumentException("dimensions of index not match dimensions of shape")
        }
        if (!CheckIndex(index, this.shape_)) {
            throw IndexOutOfBoundsException("index out of range")
        }
        var offset = 0
        for (i in 0..index.size) {
            offset = index[i] * this.strides_[i] + offset
        }
        return unsafe { data.read(offset) }
    }
    public operator func[](index: Array<Int64>, value!: T): Unit {
        if (index.size != this.shape_.size) {
            throw IllegalArgumentException("dimensions of index not match dimensions of shape")
        }
        if (!CheckIndex(index, this.shape_)) {
            throw IndexOutOfBoundsException("index out of range")
        }
        var offset = 0
        for (i in 0..index.size) {
            offset = index[i] * this.strides_[i] + offset
        }
        unsafe { data.write(offset, value) }
    }

    ~init() {
        match (base) {
            case None => { =>
                if (!data.isNull()) {
                    var t_data = unsafe { CPointer<Unit>(data) }
                    unsafe { free(t_data) }
                }
            }()
            case _ => ()
        }
        unsafe { releaseArrayRawData(shapePtr_) }
        unsafe { releaseArrayRawData(stridesPtr_) }
    }

    private func format(v: T): String {
        return v.toString()
    }
    private func printFixedLength(v: T, maxWordWith: Int64): String {
        var padding = " "
        return format(v).padLeft(maxWordWith, padding: padding)
    }
    private func rstrip(s: String): String {
        var leftmost = s.size
        for (i in leftmost-1..-1:-1) {
            if (Char(s[i]) == ' ' || Char(s[i]) == '\t') {
                leftmost = leftmost - 1
            } else {
                break
            }
        }
        return s[0..leftmost]
    }
    private func appendLine(s: String, line: String, word: String,
                            nextLinePrefix: String, lineWidth: Int64): (String, String) {
        var needsWrap = line.size + word.size > lineWidth
        if (line.size <= nextLinePrefix.size) {
            needsWrap = false
        }

        var ns = s
        var nline = line
        if (needsWrap) {
            ns = s + rstrip(line) + "\n"
            nline = nextLinePrefix
        }
        nline = nline + word
        return (ns, nline)
    }
    private func recursiveStr(vl: ArrayList<Int64>,
                              summaryStr: String,
                              prefixS: String,
                              lineWidth: Int64,
                              maxWordWith: Int64): String {
        let sep = " "
        // let lineSep = "\n"

        var d = vl.size
        if (d == this.shape_.size) {
            return printFixedLength(this[vl], maxWordWith)
        }

        var curLen = this.shape_[d]
        var showSummary = false
        if (summaryStr.size != 0 && curLen > 2*3) {
            showSummary = true
        }

        var leadingEleCount = 0
        var tailingEleCount = curLen
        if (showSummary) {
            leadingEleCount = 3
            tailingEleCount = 3
        }

        var nextPrefixS = prefixS + " "
        var s = ""
        var nextLineWidth = lineWidth - 1     // 考虑 ] 的对齐
        if (d == this.shape_.size - 1) {
            var line = prefixS
            for (i in 0..leadingEleCount) {
                vl.append(i)
                var word = recursiveStr(vl, summaryStr, nextPrefixS, nextLineWidth, maxWordWith)
                var res = appendLine(s, line, word, prefixS, lineWidth-1) // -1 是为了给 ] 留位置
                s = res[0]; line = res[1]
                line = line + sep
                vl.remove(vl.size-1)
            }
            if (showSummary) {
                var res = appendLine(s, line, summaryStr, prefixS, lineWidth-1)
                s = res[0]; line = res[1]
                line = line + sep
            }
            for (i in tailingEleCount..1:-1) {
                vl.append(curLen-i)
                var word = recursiveStr(vl, summaryStr, nextPrefixS, nextLineWidth, maxWordWith)
                var res = appendLine(s, line, word, prefixS, lineWidth-1) // -1 是为了给 ] 留位置
                s = res[0]; line = res[1]
                line = line + sep
                vl.remove(vl.size-1) 
            }
            vl.append(curLen-1)
            var word = recursiveStr(vl, summaryStr, nextPrefixS, nextLineWidth, maxWordWith)
            var res = appendLine(s, line, word, prefixS, lineWidth-1) // -1 是为了给 ] 留位置
            s = res[0]; line = res[1]
            vl.remove(vl.size-1)
            s = s + line
        } else {
            var lineSep = rstrip(sep)
            for (_ in 0..this.shape_.size-d-1) {
                lineSep = lineSep + "\n"
            }
            for (i in 0..leadingEleCount) {
                vl.append(i)
                var nested = recursiveStr(vl, summaryStr, nextPrefixS, nextLineWidth, maxWordWith)
                s = s + prefixS + nested + lineSep
                vl.remove(vl.size-1)
            }
            if (showSummary) {
                s = s + prefixS + summaryStr + lineSep
            }
            for (i in tailingEleCount..1:-1) {
                vl.append(curLen-i)
                var nested = recursiveStr(vl, summaryStr, nextPrefixS, nextLineWidth, maxWordWith)
                s = s + prefixS + nested + lineSep
                vl.remove(vl.size-1)
            }
            vl.append(curLen - 1)
            var nested = recursiveStr(vl, summaryStr, nextPrefixS, nextLineWidth, maxWordWith)
            s = s + prefixS + nested
            vl.remove(vl.size-1)
        }
        s = "[" + s[prefixS.size..] + "]"
        return s
    }
    private func getMaxWordWidth(dl: ArrayList<Int64>, summaryStr: String): Int64 {
        var d = dl.size
        if (d == this.shape_.size) {
            if (this[dl].toString().contains("\n")) {
                return -1
            } else if (this[dl].toString().size > 15) {
                return -2
            } else {
                return this[dl].toString().size
            }
        }
        var curLen = this.shape_[d]
        var showSummary = false
        if (summaryStr.size != 0 && curLen > 2*3) {
            showSummary = true
        }

        var leadingEleCount = 0
        var tailingEleCount = curLen
        if (showSummary) {
            leadingEleCount = 3
            tailingEleCount = 3
        }

        var curMaxWordWidth = 0
        for (i in 0..leadingEleCount) {
            dl.append(i)
            var curWidth = getMaxWordWidth(dl, summaryStr)
            dl.remove(dl.size - 1)
            if (curWidth < 0) {
                curMaxWordWidth = curWidth
                return curMaxWordWidth
            } else {
                curMaxWordWidth = max(curMaxWordWidth, curWidth)
            }
        }
        for (i in tailingEleCount..0:-1) {
            dl.append(curLen - i)
            var curWidth = getMaxWordWidth(dl, summaryStr)
            dl.remove(dl.size - 1)
            if (curWidth < 0) {
                curMaxWordWidth = curWidth
                return curMaxWordWidth
            } else {
                curMaxWordWidth = max(curMaxWordWidth, curWidth)
            }
        }
        return curMaxWordWidth
    }
    public func toString() : String {
        var summaryStr = ""
        if (this.size > 1000) {
            summaryStr = "..."
        }
        var vl = ArrayList<Int64>()
        var dl = ArrayList<Int64>()
        var prefixS = " "
        var maxWordWith: Int64 = getMaxWordWidth(dl, summaryStr)
        if (maxWordWith <= 0) {
            if (maxWordWith == -1) {
                NDLOG(WARNING, "XDArray element contains carriage return character")
            } else if (maxWordWith == -2) {
                NDLOG(WARNING, "XDArray contains elements which size greater than 15")
            }
            return ""
        }
        var s = recursiveStr(vl, summaryStr, prefixS, 75, maxWordWith)
        return s
    }
}