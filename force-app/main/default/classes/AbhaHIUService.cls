@RestResource(urlMapping='/health-information/cm/request')
global with sharing class AbhaHIUService {

     @HttpGet
    global static void getHIUData() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String queryid = req.params.get('queryid');
        queryid= queryid.replaceAll('[^0-9]', '');
        
        if (String.isBlank(queryid)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(buildErrorResponse('ABDM-1000', 'Missing either Aadhaar or ABHA number.'));
            res.addHeader('Content-Type', 'application/json');
            return;
        }
        
        List<Mock_Abha__c> abhaRecords = [
             select Name,ABHAid__c,ABHA_Address__c,AadhaarNumber__c,address__c,
            dayOfBirth__c,yearOfBirth__c,monthOfBirth__c,mobile__c,districtCode__c,
            districtName__c,firstName__c,middleName__c,lastName__c,gender__c,
            status__c,stateName__c,subdistrictName__c,kycVerified__c,
            verificationStatus__c,verificationType__c,pincode__c,
            CreatedDate,stateCode__c,Patient_History__c from Mock_Abha__c 
            where  (AadhaarNumber__c = :queryid or SimplifiedAbhaID__c = :queryid) LIMIT 1
        ];
    	
        if (abhaRecords.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf(buildErrorResponse('ABDM-1030', 'Record not found'));
            res.addHeader('Content-Type', 'application/json');
            return;
        }

        Mock_Abha__c record = abhaRecords[0];
        if (record.Patient_History__c == null || record.Patient_History__c.trim() == '') {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf(buildErrorResponse('ABDM-1031', 'No HIU data available'));
            res.addHeader('Content-Type', 'application/json');
            return;
        }
        Map<String, Object> responseBody = new Map<String, Object>{
            'ABHANumber' => record.ABHAid__c,
            'AadhaarNumber' => record.AadhaarNumber__c,
            'preferredAbhaAddress' => record.ABHA_Address__c,
            'mobile' => maskMobile(record.mobile__c),
            'firstName' => record.firstName__c,
            'middleName' => record.middleName__c,
            'lastName' => record.lastName__c,
            'name' => record.Name,
            'yearOfBirth' => String.valueOf(record.yearOfBirth__c),
            'dayOfBirth' => String.valueOf(record.dayOfBirth__c),
            'monthOfBirth' => String.valueOf(record.monthOfBirth__c),
            'gender' => record.gender__c,
            'profilePhoto' => '',
            'status' => record.status__c,
            'stateCode' => String.valueOf(record.stateCode__c),
            'districtCode' => String.valueOf(record.districtCode__c),
            'pincode' => record.pincode__c,
            'address' => record.address__c,
            'kycPhoto' => '',
            'kycVerified' => record.kycVerified__c,
            'verificationStatus' => record.verificationStatus__c,
            'verificationType' => record.verificationType__c,
            'stateName' => record.stateName__c,
            'districtName' => record.districtName__c,
            'subdistrictName' => record.subdistrictName__c,
            'authMethods' => new List<String>{'MOBILE_OTP','AADHAAR_BIO','AADHAAR_OTP','DEMOGRAPHICS','PASSWORD'},
            'tags' => new Map<String, String>(),
            'createdDate' => record.CreatedDate.format('dd-MM-yyyy'),
            'PatientHistory' => record.Patient_History__c
        };
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(responseBody));
        res.addHeader('Content-Type', 'application/json');
    }
    private static String maskMobile(String mobile) {
        if (String.isBlank(mobile) || mobile.length() < 10) return mobile;
        return '******' + mobile.right(4);
    }
    private static String buildErrorResponse(String code, String message) {
        Map<String, Object> errorBody = new Map<String, Object>{
            'error' => new Map<String, String>{
                'code' => code + ': ',
                    'message' => message
                    }
        };
        return JSON.serialize(errorBody);
    }
}