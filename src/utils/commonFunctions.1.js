var path = require('path')
const TAG = path.basename(__filename) + '----->	';
var AWS = require('aws-sdk')
var dbConfig = require('../../config/dbConfig.json');
var configURL = require('../../config/config.json');
//var filepath = require('../../public/uploadedData/');
// var dbQuery=require('../services/dbQuery.js')
var json2xls = require('json2xls')
var json2csv = require('json2csv')
var ceil = require("math-ceil");
var sql = require('mssql');
var fs = require("fs");
var connection = "";
var request = "";
//var getConfig = require("getconfig");
const chalk = require('chalk');
//F:\smartrepair\smartrepairapp\public\uploadedData\UPSAllFile

var self = module.exports = {

    IsLunnValid: (function (arr) {
        return function (ccNum) {
            if (!ccNum) {
                return false
            }
            ccNum = typeof ccNum != 'string' ? ccNum.toString() : ccNum
            if (!ccNum.length) {
                return false
            }
            if (ccNum.length != 15) {
                return false
            }
            var
                len = ccNum.length,
                bit = 1,
                sum = 0,
                val;
            while (len) {
                val = parseInt(ccNum.charAt(--len), 10);
                if (!(val >= 0 || val <= 9)) {
                    return false
                }
                sum += (bit ^= 1) ? arr[val] : val;
            }
            return sum && sum % 10 === 0;
        };
    }([0, 2, 4, 6, 8, 1, 3, 5, 7, 9])),

    //=============change the date fromate===========
    GetFormatedDate: function (date, informat, outformat) {
        informat = informat;
        if (outformat == 'ISO') {
            outformat = null
        } else if (outformat) {
            outformat = outformat
        } else {
            outformat = outformat || 'YYYY-MM-DD HH:mm:ss.SSS';
        }
        return (date == null || date.length == 0) ? null : moment(date, informat).format(outformat)
    },

    //===========connection with data base for master data=========
    GetMasterData: function (sendQuery) {
        var deferred = q.defer();
        query = sendQuery;
        dbQuery(query)
            .then(function (result) {
                deferred.resolve(result);
            })
            .catch(function (err) {
                deferred.reject('invaild data- sql');
            })
            .done();
        return deferred.promise;
    },
    /*isDateFormatValid : function(getDate){
        if (! moment(getDate,getConfig.dateVariable,true).isValid()) {
            return "Invalid date";
        }
          return getDate;
    },*/
    getGUID: function (separator) {
        var delim = separator || "-";

        function S4() {
            return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
        }
        return (S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4());
    },

    //==============generate new Excel file=========
    getGenerateExcel: function (jsonData, filePath) {
        self = this;
        var updatedExcelFile = json2xls(jsonData)
        //=======checking file exist or not===========
        fs.stat(filePath, function (err, stat) {
            if (err) {
                return console.error(err);
            }
            // Check file type
            // console.log("isFile ? " + stat.isFile());
            // console.log("isDirectory ? " + stat.isDirectory());
            //   if(err == null){
            //       self.deleteLocalFile(filePath)
            //   }
        })
        //========generate excle file code=======
        fs.writeFileSync(filePath, updatedExcelFile, 'binary');
        return filePath
    },

    //==============delete Excel file from system=========
    deleteLocalFile: function (localFilePath) {
        console.log("delete", localFilePath);
        fs.unlink(localFilePath, function (error, response) {
            if (error) {
                console.log(chalk.red(TAG + __line + 'Error deleting local file' + JSON.stringify(error)))
            } else {
                console.log(chalk.green(TAG + __line + 'Temporary local file deleted'))
            }
        })
    },

    //==============generate new Excel file=========
    getGenerateFileToCSV: function (data) {
        var deferred = q.defer();
        self = this;
        var fname = 'D:/FTP/APAR/Independence/partnerportalService/public/' + new ObjectID() + '-jobCreate.csv';
        var fileDetails = {
            filePathWithName: fname, // Path with file name where you want to save csv file for get in bulk insert query
            fieldTerminator: ';' // column deliminator (default "," comman)
        }
        var headerData = require('../views/dataviews/mstExcelHeaderColumn.js')();
        filterHeaderData = _.pluck(headerData, 'headerColumnName')
        var newData = [];
        for (i = 0; i < data.length; i++) {
            var rowValidArray = data[i].validJobArray.length > 0 ? data[i].validJobArray : [];
            for (var k = 0; k < rowValidArray.length; k++) {
                var newObj = {};
                for (j = 0; j < filterHeaderData.length; j++) {
                    newObj[filterHeaderData[j]] = rowValidArray[k][filterHeaderData[j]];
                }
                newObj["fileName"] = fileDetails.filePathWithName;
                newData.push(newObj);
            }
        }
        if (newData && newData.length > 0) {
            var csv = json2csv({
                data: newData,
                del: fileDetails.fieldTerminator,
                hasCSVColumnTitle: false,
                defaultValue: '',
                // fields: filterHeaderData,
                quotes: ''
                // eol: '@'
            });
            fs.writeFile(fileDetails.filePathWithName, csv, function (err) {
                console.log('file saved', err);
                deferred.resolve(fileDetails)
            });
        } else {
            deferred.resolve(fileDetails)
        }
        return deferred.promise;
    },

    setNull: function (str) {
        return (str == null) ? null : str;
    },

    // check if the given string contains only digits.
    isNumeric: function (str) {
        var regex = /^[0-9]+$/;
        return regex.test(str);
    },

    // used to get from and to data and Logistic for label generation
    fromToAndlogisticdetails: function (currentUserData, requestbody, ginId, logInfo) {

        winstonlogger.infoMongoLog({
            type: "info",
            step: logInfo.stepNumber,
            function: logInfo.functionName,
            message: "Request of fromToAndlogisticdetails",
            status: "open",
            headers: logInfo.headers,
            data: {
                currentUserData: currentUserData,
                requestbody: requestbody,
                ginId: ginId
            }
        });

        var deferred = q.defer();
        var fromServiceLocationId = currentUserData.serviceLocationId;
        var toServiceLocationId = requestbody.toServiceLocationId;
        var ginId = ginId;
        var courierName = requestbody.courierName;
        var roleid = currentUserData.roleId;
        var serviceType = requestbody.serviceType;
        var response = {};
        connection = new sql.Connection(dbConfig.IMO, function (err) {
            if (err) {
                response.code = "500";
                response.msg = err.message;   
                deferred.reject(response);

            } else {
                request = new sql.Request(connection);
                request.input('fromServiceLocationId', fromServiceLocationId ? fromServiceLocationId : null);
                request.input('toServiceLocationId', toServiceLocationId ? toServiceLocationId : null);
                request.input('ginId', ginId ? ginId : null);
                request.input('courierName', courierName ? courierName : null);
                request.input('roleid', roleid ? roleid : null);
                request.input('serviceType', serviceType ? serviceType : null)
                request.input('commandType', "getFromTodataAndLogistic");
                request.execute('API_OrderShippment', function (err, recordset, returnVal) {
                    if (err) {
                        response.code = "400";
                        response.message = err.message;
                        deferred.reject(response);
                    } else {

                        winstonlogger.infoMongoLog({
                            type: "info",
                            step: (logInfo.stepNumber + 1),
                            function: logInfo.functionName,
                            message: "fromToAndlogisticdetails: API_OrderShippment SP response",
                            status: "open",
                            headers: logInfo.headers,
                            data: {
                                recordset: recordset,
                                returnVal: returnVal
                            }
                        });

                        if (recordset[0].length == 0) {
                            response.code = "400";
                            response.message = "Sender information Not found";
                            deferred.reject(response);
                        } else if (recordset[1].length == 0) {
                            response.code = "400";
                            response.message = "Recipient information Not found";
                            deferred.reject(response);
                        } else {
                            response.senderInfo = recordset[0];;
                            response.recipientInfo = recordset[1];
                            response.logisticPartnerInfo = recordset[2];
                            response.code = "200";
                            response.message = "Success";
                            deferred.resolve(response);
                        }

                    }
                });
            }
        });
        return deferred.promise;
    },

    // it is used to generate label and generated label is stored in S3 bucket
    getTrackingnumber: function (FromToReqBody, requestbody, countryCode, logInfo) {

        var deferred = q.defer()
        var responseLabel = {};
        AWS.config.loadFromPath('./config/awsConfig.json')
        var labelUploadBucket = new AWS.S3({
            apiVersion: '2006-03-01',
            params: {
                Bucket: 'b2x-imo-rw' //TEST
            }
        })
        try {

            var weightUnit = requestbody.weightUnit;

            var logisticPartnerName = requestbody.courierName;

            var referencenumber = requestbody.referenceNumber;

            var senderInfo = FromToReqBody.senderInfo;

            var recipientInfo = FromToReqBody.recipientInfo;

            var logisticPartner = FromToReqBody.logisticPartnerInfo;

            var dangerousGoods = requestbody.dangerousGoods;

            var weight = requestbody.weight

            var request = require("request");


            var DM_DEVAuthToken = configURL.labelAuthToken
            DM_DevURL = configURL.generateLabelURL;



            if (countryCode == "US" && logisticPartnerName.toLowerCase() == "ups") {
                if (_.isEmpty(weight)) {
                    weight = null;
                } else {
                    weight = ceil(weight);
                }
            } else {
                if (_.isEmpty(weight)) {
                    weight = 1;
                } else {
                    weight = ceil(weight);
                }
            }

            if (logisticPartnerName.toLowerCase() != 'dhl') {
                dangerousGoods.code = null;
                dangerousGoods.remark = null;
            }

            var options = {
                method: 'POST',
                url: DM_DevURL, //Test URL//
                headers: {
                    'cache-control': 'no-cache',
                    'api-key': DM_DEVAuthToken,
                    'content-type': 'application/json'
                },
                body: [{
                    shipmentConfiguration: {
                        accountNumber: logisticPartner[0].accountNumber,
                        weightUnit: weightUnit,
                        referenceNumber: referencenumber,
                        returnService: logisticPartner[0].returnService,
                        serviceType: logisticPartner[0].serviceType,
                    },
                    packageInfo: [{
                        referenceNumber: referencenumber,
                        weight: weight
                    }],
                    senderInfo: {
                        name: senderInfo[0].slFromName,
                        address: senderInfo[0].slFromAddress,
                        city: senderInfo[0].slFromCity,
                        state: senderInfo[0].slFromState,
                        postalCode: senderInfo[0].slFromPostalCode,
                        country: senderInfo[0].slFromCountry,
                        email: senderInfo[0].slFromEmail,
                        phone: senderInfo[0].slFromPhone
                    },
                    recipientInfo: {
                        name: recipientInfo[0].slToName,
                        address: recipientInfo[0].slToAddress,
                        city: recipientInfo[0].slToCity,
                        state: recipientInfo[0].slToState,
                        country: recipientInfo[0].slToCountry,
                        phone: recipientInfo[0].slToPhoneNo,
                        postalCode: recipientInfo[0].slToPostalCode
                    },
                    dangerousGoods: {
                        code: dangerousGoods.code,
                        remark: dangerousGoods.remark
                    },
                    logisticPartner: logisticPartnerName,
                    externalAccount: {
                        password: logisticPartner[0].password,
                        user: logisticPartner[0].user,
                        token: logisticPartner[0].token,
                        accountNumber: logisticPartner[0].externalAccountNumber
                    }
                }],
                json: true
            };

            options.body[0].shipmentConfiguration = _.omit(options.body[0].shipmentConfiguration, function (value, key, object) {
                return _.isEmpty(value) && !_.isNumber(value) && !_.isBoolean(value)
            });
            options.body[0].packageInfo[0] = _.omit(options.body[0].packageInfo[0], function (value, key, object) {
                return _.isEmpty(value) && !_.isNumber(value) && !_.isBoolean(value)
            });
            options.body[0].senderInfo = _.omit(options.body[0].senderInfo, function (value, key, object) {
                return _.isEmpty(value) && !_.isNumber(value) && !_.isBoolean(value)
            });
            options.body[0].recipientInfo = _.omit(options.body[0].recipientInfo, function (value, key, object) {
                return _.isEmpty(value) && !_.isNumber(value) && !_.isBoolean(value)
            });
            options.body[0].dangerousGoods = _.omit(options.body[0].dangerousGoods, function (value, key, object) {
                return _.isEmpty(value) && !_.isNumber(value) && !_.isBoolean(value)
            });
            options.body[0].externalAccount = _.omit(options.body[0].externalAccount, function (value, key, object) {
                return _.isEmpty(value) && !_.isNumber(value) && !_.isBoolean(value)
            });
            options.body[0] = _.omit(options.body[0], _.isEmpty)

            winstonlogger.infoMongoLog({
                type: "logs",
                step: logInfo.stepNumber,
                function: logInfo.functionName,
                status: "inprogress",
                message: "getTrackingnumber: label generation request ",
                headers: logInfo.headers,
                data: options.body
            });

            request(options, function (error, response, body) {
                try {
                    var responseDM = {};
                    var resDM = response.body;
                    var content = resDM.content[0];

                    winstonlogger.infoMongoLog({
                        type: "logs",
                        step: (logInfo.stepNumber + 1),
                        function: logInfo.functionName,
                        status: "inprogress",
                        message: "getTrackingnumber: label generation response",
                        headers: logInfo.headers,
                        data: response.body
                    });

                    if (resDM.status_code == "200") {
                        if (content == null) {
                            responseLabel.message = resDM.errors[0].message[0];
                            responseLabel.message = 400;
                            deferred.reject(responseDM)
                        } else {
                            var err = content.error;
                            if (err != null) {
                                responseLabel.code = content.status_code;
                                responseLabel.message = content.message;
                                deferred.reject(responseDM)
                            } else {

                                filePath = content.trackingNumber + "." + content.labelType
                                buf = new Buffer(content.label[0], 'base64')
                                // console.log("111111111111111111", request.body.data.substring(22))
                                var data = {
                                    Key: "SRPOPUpload/" + filePath,
                                    Body: buf,
                                    ContentEncoding: 'base64',
                                    ContentType: "image/" + content.labelType,
                                    ACL: 'public-read'
                                };
                                labelUploadBucket.upload(data, function (err, data) {
                                    if (err) {
                                        responseLabel.code = 400;
                                        responseLabel.message = "Failed to generate label";
                                        responseLabel.trackingNumber = null;
                                        responseLabel.filePath = null;
                                        deferred.reject(response);
                                    } else {
                                        responseLabel.code = 200;
                                        responseLabel.message = "Success";
                                        responseLabel.trackingNumber = content.trackingNumber;
                                        responseLabel.filePath = "SRLabelUpload/" + filePath;
                                        // console.log(JSON.stringify(data.Location));
                                        deferred.resolve(responseLabel);
                                    }
                                });

                                // fs.writeFile('./public/uploadedData/UPSAllFile/' + filePath, content.label[0], 'base64', function (err) {
                                //     if (err != null) {
                                //         responseLabel.code = 400;
                                //         responseLabel.message = "Failed to generate label";
                                //         responseLabel.trackingNumber = null;
                                //         responseLabel.filePath = null;
                                //         deferred.reject(response);

                                //     } else {
                                //         responseLabel.code = 200;
                                //         responseLabel.message = "Success";
                                //         responseLabel.trackingNumber = content.trackingNumber;
                                //         responseLabel.filePath = 'UPSAllFile/' + filePath;
                                //         deferred.resolve(responseLabel);
                                //     }

                                //});
                            }
                        }
                    } else {
                        responseLabel.code = 400;
                        responseLabel.message = "Failed to generate label";
                        responseLabel.trackingNumber = null;
                        responseLabel.filePath = null;
                        responseLabel.reject(response);
                    }
                } catch (e) {
                    responseLabel.code = 400;
                    responseLabel.message = "Failed to generate label";
                    responseLabel.trackingNumber = null;
                    responseLabel.filePath = null;
                    deferred.reject(response);
                }
            });
        } catch (e) {
            responseLabel.code = 400;
            responseLabel.message = "Failed to generate label";
            responseLabel.trackingNumber = null;
            responseLabel.filePath = null;
            deferred.reject(response);
        }
        return deferred.promise;
    },

    /**
     * This function checks whether the requested information is within data obj or not
     * @param {object} reqBody - Request body of an API
     * @param {boolean} isRespDataObj - If true then response containing data property will have an empty object value else empty array value
     * @param {boolean} doesErrorRespContainsCode - If true then response containing error property will have error code
     */
    doesRequestContainsDataObj: function (reqBody, isRespDataObj, doesErrorRespContainsCode) {

        var deferred = q.defer();
        if (_.isObject(reqBody.data)) {
            deferred.resolve();
        } else {
            deferred.reject({
                status: "fail",
                message: "Invalid request",
                data: (isRespDataObj && isRespDataObj === true ? {} : []),
                error: (doesErrorRespContainsCode && doesErrorRespContainsCode === true ? ([{
                    "code": "ERRCM_0001",
                    "message": ["data object is required"]
                }]) : ["data object is required"])
            });
        }
        return deferred.promise;
    },

    // below function is used to generate proper request parameter while hitting PostGreSQL function
    getPostGreParam: function (paramValue, paramType) {

        var paramIsArray = _.isArray(paramValue);

        if (paramIsArray) {
            var paramString = "";
            _.each(paramValue, function (pElement) {
                if (_.isEmpty(paramString)) {
                    paramString = "'" + pElement + "'";
                } else {
                    paramString = paramString + ",'" + pElement + "'";
                }
            });
            paramValue = paramString;
        }

        paramType = _.isEmpty(paramType) ? '' : paramType.toString();
        var retVal = null;
        switch (paramType.toLowerCase()) {
            case 'string':
                retVal = _.isEmpty(paramValue) ? null : "'" + paramValue.replace(/'/g, "\'\'") + "'";
                break;
            case 'arrayOfString':
                retVal = _.isEmpty(paramValue) ? null : paramValue;
            case 'int':
            default:
                retVal = paramValue ? paramValue : null;
                break;
        }
        return retVal;
    },

    // following function converts string to lower camel case
    convertToCamelCase: function (inputString) {
        if (_.isEmpty(inputString)) {
            return "";
        } else {
            var outputString = inputString.toString().split(" ");
            outputString[0] = outputString[0].toLowerCase();
            outputString = outputString.join("");
            return (outputString);
        }
    },

    // following function converts input date to UTC datetime format
    convertToUtcDate: function (inputDate) {
        return (moment(inputDate).isValid() && inputDate != null) ? moment(moment(inputDate).format('YYYY-MM-DD HH:mm:ss.SSS')).utc().toISOString() : null;
    },

    // upload file in S3 Bucket
    uploadFileToS3Bucket: function (filePathToUpload, s3FolderName, newFileNameWithExtn) {
        var deferred = q.defer();
        fs.readFile(filePathToUpload, function (err, buf) {
            if (err) {
                deferred.reject(err);
            }

            AWS.config.loadFromPath('./config/awsConfig.json')
            var s3bucket = new AWS.S3({
                params: {
                    Bucket: 'b2x-imo-rw'
                }
            });
            var getContentType;
            var getFileExtenstion = newFileNameWithExtn.split('.').pop();
            if (getFileExtenstion && getFileExtenstion.toLowerCase() === 'pdf') {
                getContentType = "application/pdf";
            } else {
                getContentType = "Content-Type:text/plain";
            }

            var data = {
                Key: "inventoryManagement/" + (_.isEmpty(s3FolderName) ? '' : s3FolderName + '/') + newFileNameWithExtn,
                Body: buf,
                ContentEncoding: 'base64',
                ContentType: getContentType,
                ACL: 'public-read'
            };
            // console.log("datadatadatadata", data)
            s3bucket.upload(data, function (err, datas) {
                // console.log("datasdatasdatas", datas, err);
                if (err) {
                    deferred.reject(err);
                } else {

                    deferred.resolve({
                        requestedFilePathToUpload: filePathToUpload,
                        s3FilePath: datas.Location
                    });
                }
            });
        });
        return deferred.promise;
    },

    /**
     * This function trims request body
     * @param {object} body - Request body of an API
     */
    trimBody: function (body) {
        if (body && Object.keys(body).length > 0) {
            Object.keys(body).forEach(function (key) {
                var value = body[key];

                if (typeof value === 'string')
                    return body[key] = value.trim();

                if (typeof value === 'object')
                    self.trimBody(value);
            });
        }
        return body;
    },

    /* This function is used to fetch the price of parts from Partner Portal using oemCode, soldToCode & partCode these params */
    getPartPriceFromPP: function (reqBody, logInfo) {
        var deferred = q.defer();
        var finalResponse = {};

        if (reqBody && reqBody.partCode && reqBody.partCode.length > 0) {

            winstonlogger.infoMongoLog({
                type: "logs",
                step: (logInfo.stepNumber),
                function: logInfo.functionName,
                status: "inprogress",
                message: "getPartPriceFromPP: part price request",
                headers: logInfo.headers,
                data: reqBody
            });

            var request = require("request");
            var url = configURL.mspomApi + 'partDetailsFromPartCodeSR';
            var options = {
                method: 'POST',
                url: url,
                headers: {
                    'authtoken': configURL.mspomAuthToken,
                    'content-type': 'application/json'
                },
                body: reqBody,
                json: true
            };

            request(options, function (error, response, body) {
                try {
                    var responsePP = (response && response.body) ? response.body : {};
                    // console.log('responsePPresponsePP', responsePP);

                    winstonlogger.infoMongoLog({
                        type: "logs",
                        step: (logInfo.stepNumber + 1),
                        function: logInfo.functionName,
                        status: "inprogress",
                        message: "getPartPriceFromPP: part price response",
                        headers: logInfo.headers,
                        data: response.body
                    });

                    if (responsePP && responsePP.ResponseData && responsePP.ResponseData.length > 0) {
                        if (responsePP.ResponseData.length == reqBody.partCode.length) {
                            finalResponse = {
                                status: "success",
                                message: "Part price details found successfully",
                                data: responsePP,
                                error: []
                            };
                        } else {
                            finalResponse = {
                                status: "success",
                                message: "Part price details partially found successfully",
                                data: responsePP,
                                error: []
                            };
                        }
                    } else {
                        finalResponse = {
                            status: "fail",
                            message: "Part price details not found",
                            data: responsePP,
                            error: []
                        };
                    }
                    deferred.resolve(finalResponse);

                } catch (e) {
                    finalResponse = {
                        status: "fail",
                        message: "Part price details not found",
                        data: {},
                        error: []
                    };
                    deferred.resolve(finalResponse);
                }
            });
        } else {
            finalResponse = {
                status: "fail",
                message: "Part details not found",
                data: {},
                error: []
            }
            deferred.resolve(finalResponse);
        }

        return deferred.promise;
    },

    /**
     * This function updates service request status against job
     * @param {{service_number: String, action_status: Number, service_location_code: String}[]} serviceRequestData - Request body of an API
     */
    updateServiceRequestDetails: function (serviceRequestData) {
        var deferred = q.defer();

        winstonlogger.infoMongoLog({
            type: "logs",
            step: 1,
            function: "updateServiceRequestDetails",
            status: "inprogress",
            message: "updateServiceRequestDetails request initiated",
            headers: null,
            data: serviceRequestData
        });

        var serviceRequestUpdate = {
            method: 'POST',
            url: configURL.espAPIUrl + 'updateServiceRequestStatus',
            headers: {
                authtoken: configURL.espAuthToken,
                'content-type': 'application/json'
            },
            body: {
                data: {
                    serviceRequestData: serviceRequestData ? serviceRequestData : []
                }
            },
            json: true
        };
        try {
            var postRequestDetails = require("request");

            winstonlogger.infoMongoLog({
                type: "logs",
                step: 2,
                function: "updateServiceRequestDetails",
                status: "inprogress",
                message: "Post info generated",
                headers: null,
                data: serviceRequestUpdate
            });

            postRequestDetails(serviceRequestUpdate, function (error, response, body) {

                winstonlogger.infoMongoLog({
                    type: "logs",
                    step: 3,
                    function: "updateServiceRequestDetails",
                    status: "inprogress",
                    message: "post done",
                    headers: null,
                    data: {
                        error: error,
                        body: body
                    }
                });

                if (error) {
                    deferred.reject({
                        status: "fail",
                        message: "fail to update service request status",
                        error: error
                    })
                } else {
                    if (body.status == "success") {
                        deferred.resolve(body)
                    } else {
                        deferred.reject({
                            status: "fail",
                            message: "fail to update service request status",
                            error: body
                        })
                    }
                }
            });
            return deferred.promise;
        } catch (e) {
            console.log(e)

            winstonlogger.errorMongoLog({
                type: "error",
                step: 4,
                function: "updateServiceRequestDetails",
                status: "inprogress",
                message: "Catch block",
                headers: null,
                data: e
            });

            deferred.reject({
                status: "fail",
                message: "fail to update service request status",
                error: e
            })
        }
    },

    /**
     * This function rounds double number with 2 precision
     * @param double no - Input number which is to be rounded with 2 precision after decimal point
     */
    roundNumberTo2Precision: function (no) {
        return _.isNumber(no) ? (Math.round(no * 100) / 100) : no;
    }

}