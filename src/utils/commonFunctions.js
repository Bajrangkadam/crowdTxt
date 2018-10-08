import _ from 'underscore';
//F:\smartrepair\smartrepairapp\public\uploadedData\UPSAllFile

var self = module.exports = {

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