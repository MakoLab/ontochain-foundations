// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library Date {
   
   function toISOString(bytes memory _date) public pure returns(bytes memory){
       return intToDateString(stringToInt(_date));
   }

   function leapYears(uint256 _year) private pure returns(bool){
      if(_year%400==0 || (_year%100!=0 && _year%4 == 0)){
         return true;
      }
      return false;
   }

   function intToDateString(uint256 _date) private pure returns(bytes memory _result){

      uint256 _day = (_date/86400);
      uint256 _year = 1970;

      while(_day >= 365){
         if(leapYears(_year)){
            _day-=366;
         }
         else{
            _day-=365;  
         }
         _year+=1;
      }
      _day=_day+1;

      uint8[12] memory daysOfMonth = [31,28,31,30,31,30,31,31,30,31,30,31];
      uint256 _mounth = 1;
      uint8 index = 0;
      if(leapYears(_year)){
         while(true){
            if(index == 1){
               if(_day < 29) break;
               _mounth+=1;
               _day-=29;
            }
            else{
               if(_day < daysOfMonth[index]) break;
               _mounth+=1;
               _day-= daysOfMonth[index];
            }
            index+=1;
         }
      }
      else{
         while(true){
            if(_day < daysOfMonth[index]) break;
               _mounth+=1;
               _day-= daysOfMonth[index];
               index+=1;
         }    
      }

      if(_day == 0){
         if(_mounth == 2 && leapYears(_year)){
            _day = 29;
         }
         else{
            _day = daysOfMonth[_mounth-1];
         }
      }

      _result = uint2str(_year);

      if(_mounth < 10) _result = abi.encodePacked(_result, "-0", uint2str(_mounth));
      else _result = abi.encodePacked(_result, "-", uint2str(_mounth));

      if(_day < 10) _result = abi.encodePacked(_result, "-0", uint2str(_day),'T');
      else  _result = abi.encodePacked(_result, "-", uint2str(_day),'T');

      _year = (_date%86400)/3600;
      if(_year < 10) _result = abi.encodePacked(_result,"0", uint2str(_year));
      else  _result = abi.encodePacked(_result, uint2str(_year));

      _year = (_date%3600)/60;
      if(_year < 10) _result = abi.encodePacked(_result, ":0", uint2str(_year));
      else  _result = abi.encodePacked(_result, ":", uint2str(_year));

      _year = _date%60;
      if(_year < 10) _result = abi.encodePacked(_result, ":0", uint2str(_year),".000Z");
      else  _result = abi.encodePacked(_result, ":", uint2str(_year),".000Z");

   }

   function stringToInt(bytes memory date) private pure returns (uint256 time){

      //2012-12-12T09:21:12 +10:30 -> length
      //2012-12-12T09:21:12 -10:30

      //secundy
      bytes memory tmp = abi.encodePacked(date[18], date[19]);
      time+= parseInt(tmp);

      //minuty
      tmp = abi.encodePacked(date[15], date[16]);
      time+= parseInt(tmp)*60;

      tmp = abi.encodePacked(date[12], date[13]);
      time+= parseInt(tmp)*3600;

      tmp = abi.encodePacked(date[9], date[10]);
      time+= (parseInt(tmp)-1)*86400;

      tmp = abi.encodePacked(date[1], date[2], date[3], date[4]);
      uint256 _year = parseInt(tmp);

      tmp = abi.encodePacked(date[6], date[7]);
      uint256 _mounth = parseInt(tmp);
      for(uint i = 1; i < _mounth; i++){
         if(i == 1 || i == 3 || i == 5 || i == 7 || i == 8 || i == 10 || i == 12){
            time+=31*24*60*60;
         }
         else if(i == 4 || i == 6 || i == 9 || i == 11){
            time+=30*24*60*60;
         }
         else{
            if(_year%4 == 0){
               if(_year%100 ==0){
                  if(_year%400 == 0){
                     time+=29*24*60*60;
                  }
                  else{
                     time+=28*24*60*60;
                  }
               }
               else{
                  time+=29*24*60*60;
               }
            }
            else{
               time+=28*24*60*60;
            }
         }
      }

      for(uint i = 1970; i < _year; i++){
         if(i % 400 == 0 || i % 4 == 0 && i % 100 != 0){
            time+= 366*24*60*60;
         }
         else{
            time+=365*24*60*60;
         }
      }

      if(date[20] == '+'){
         tmp = abi.encodePacked(date[21], date[22]);
         time-=parseInt(tmp)*3600;
         tmp = abi.encodePacked(date[24], date[25]);
         time-=parseInt(tmp)*60;
      }
      else{
         tmp = abi.encodePacked(date[21], date[22]);
         time+=parseInt(tmp)*3600;
         tmp = abi.encodePacked(date[24], date[25]);
         time+=parseInt(tmp)*60;
      }


   }

   function parseInt(bytes memory _bytesValue) private pure returns (uint256 _ret) {
        uint256 j = 10**(_bytesValue.length-1);
        for(uint256 i = 0; i < _bytesValue.length; i++) {
           //uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48) * j;
           j/=10;
        }
   }

   function uint2str(uint256 _i) private pure returns (bytes memory){
      if (_i == 0){
         return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0){
         length++;
         j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0){
         bstr[--k] = bytes1(uint8(48 + j % 10));
         j /= 10;
      }
      return bstr;
   }

}