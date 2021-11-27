pragma solidity >=0.7.0 <0.9.0;

import {Date} from "./Date.sol";

library GraphParser {

    using Date for bytes;

    function parse(string memory _terms) public pure returns(string[3][] memory){
        bytes memory stringAsBytesArray = bytes(_terms);
        uint256 counter = 0;

        bytes memory tmp;
        bytes memory subject;
        bytes memory predicate;
        bytes memory object;
        
        bool s = true;
        bool p = false;
        bool o = false;
        
        for(uint256 i = 0; i < stringAsBytesArray.length; i++){
            if(stringAsBytesArray[i] == ' ' && stringAsBytesArray[i+1] == '.'){
                counter++;
            }
        }

        string[3][] memory graph = new string[3][](counter);
        counter = 0;
        for(uint256 i = 0; i < stringAsBytesArray.length; i++){
            
            if(s){
                if(stringAsBytesArray[i] == '_' && stringAsBytesArray[i+1] == ':'){
                    for(uint256 j = i; j < stringAsBytesArray.length; j++){
                        if(stringAsBytesArray[j] == ' '){
                            subject = tmp;
                            s = false;
                            p = true;
                            tmp = "";
                            i = j;
                            break;
                        }
                        else{
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                        }

                    }
                }
                else if(stringAsBytesArray[i] == '<'){
                    for(uint256 j = i; j < stringAsBytesArray.length; j++){
                        if(stringAsBytesArray[j] == '>'){
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                            subject = tmp;
                            s = false;
                            p = true;
                            tmp = "";
                            i = j;
                            break;
                        }
                        else {
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                        }
                    }
                }
            }
            else if(p){
                if(stringAsBytesArray[i] == '<'){
                    for(uint256 j = i; j < stringAsBytesArray.length; j++){
                        if(stringAsBytesArray[j] == '>'){
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                            predicate = tmp;
                            p = false;
                            o = true;
                            tmp = "";
                            i = j;
                            break;
                        }
                        else {
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                        }
                    }
                }
            }
            else if(o){
                //Jezeli object jest Blank nodem
                if(stringAsBytesArray[i] == '_' && stringAsBytesArray[i+1] == ':'){
                    for(uint256 j = i; j < stringAsBytesArray.length; j++){
                        if(stringAsBytesArray[j] == ' '){
                            object = tmp;
                            o = false;
                            s = true;
                            tmp = "";
                            i = j;
                            // add(subject,predicate,object);
                            graph[counter][0] = string(subject);
                            graph[counter][1] = string(predicate);
                            graph[counter][2] = string(object);
                            counter++;
                            break;
                        }
                        else{
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                        }

                    }
                }
                //Jezeli object jest IRI
                else if(stringAsBytesArray[i] == '<'){
                    for(uint256 j = i; j < stringAsBytesArray.length; j++){
                        if(stringAsBytesArray[j] == '>'){
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                            object = tmp;
                            o = false;
                            s = true;
                            tmp = "";
                            i = j;
                            // add(subject,predicate,object);
                            graph[counter][0] = string(subject);
                            graph[counter][1] = string(predicate);
                            graph[counter][2] = string(object);
                            counter++;
                            break;
                        }
                        else {
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                        }
                    }
                }
                //Jezeli object jest literalem
                else if(stringAsBytesArray[i] == '"'){
                    tmp = abi.encodePacked(tmp, stringAsBytesArray[i]);
                    i = i+1;
                     for(uint256 j = i; j < stringAsBytesArray.length; j++){
                        if(stringAsBytesArray[j] == '"'){
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                            // Jezeli po literalie jest wskazany jenzyk
                            if(stringAsBytesArray[j+1] == '@'){
                                j=j+1;
                                for(uint256 v = j; v < stringAsBytesArray.length; v++){
                                    if(stringAsBytesArray[v] == ' '){
                                        j = v;
                                        break;
                                    }
                                    else{
                                        tmp = abi.encodePacked(tmp, stringAsBytesArray[v]);
                                    }
                                }
                            }      
                            // Jezeli literal jest data
                            if(stringAsBytesArray[j+1] == '^' && stringAsBytesArray[j+2] == '^'){
                                j=j+1;
                                bytes memory tmp2;
                                for(uint256 v = j; v < stringAsBytesArray.length; v++){
                                    if(stringAsBytesArray[v] == '>'){
                                        tmp2 = abi.encodePacked(tmp2, stringAsBytesArray[v]);
                                        j = v;
                                        break;
                                    }
                                    else{
                                        tmp2 = abi.encodePacked(tmp2, stringAsBytesArray[v]);
                                    }
                                }
                                if(sha256("^^<http://www.w3.org/2001/XMLSchema#dateTime>") == sha256(tmp2)){
                                    tmp = tmp.toISOString();
                                    tmp= abi.encodePacked('"',tmp,'"', tmp2);
                                }
                            }
                            object = tmp;
                            o = false;
                            s = true;
                            tmp = "";
                            i = j;
                            // add(subject,predicate,object);
                            graph[counter][0] = string(subject);
                            graph[counter][1] = string(predicate);
                            graph[counter][2] = string(object);
                            counter++;
                            break;
                        }
                        else{
                            tmp = abi.encodePacked(tmp, stringAsBytesArray[j]);
                        }

                    }
                }
            }
        }
        return graph;
    }
}