package util

from std import fs.*
from csv4cj import csv4cj.*

//Json格式输出
public func read_from_csv(fileName: String, header!: Bool = false): ArrayList<JsonValue> {
    let items = ArrayList<JsonValue>()
    var read_header = header
    //创建文件流
    let fileStream = File(fileName, OpenOption.Open(true, false))

    if (fileStream.canRead()) {
        //创建字符读取的解析流
        let stream = UTF8ReaderStream(fileStream)

        let reader = CSVReader(stream)

        //创建格式化的解析参数
        let format: CSVParseFormat = CSVParseFormat.DEFAULT

        //创建解析器
        let csvParser = CSVParser(reader, format)

        let recordList = csvParser.parseRecordsToEnd()

        //遍历每一行解析记录
        for (csvRecord in recordList) {
            if (read_header) {
                read_header = false
                continue
            }
            items.append(csvRecord.serialize().toJson())
            CSVRecord.deserialize(csvRecord.serialize())
        }
        fileStream.close()
    }

    return items
}
