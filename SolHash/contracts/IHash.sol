// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import {GraphParser} from "./GraphParser.sol";

contract IHash{

    using GraphParser for string;

    bytes private _BLANK_NODE_SUBJECT_NAME = "Magic_S";
    bytes private _BLANK_NODE_OBJECT_NAME = "Magic_O";
  
    constructor(){   
    }

    function calculate_hash_string(string memory str) public view returns(string memory) {
        //return calculate_hash(parse(str));
        return calculate_hash(str.parse());
    }
    
    function calculate_hash(string[3][] memory graph) public view returns(string memory) {
        uint256 graph_hash = 0;
        
        uint256 _triplet_hash;
        uint256 linked_hash = 0;
        
        bytes memory s;
        bytes memory p;
        bytes memory o;
        
        for (uint256 i = 0; i < graph.length; i++){
            
            s = bytes(graph[i][0]);
            p = bytes(graph[i][1]);
            o = bytes(graph[i][2]);
            
            _triplet_hash = _calculate_triple_hash(s,p,o);
            graph_hash = _modulo_hash(graph_hash, _triplet_hash);
            
            if(_is_bnode(s)){
                linked_hash = _calculate_hash_for_triples_linked_by_subject(graph, s);
                graph_hash = _modulo_hash(graph_hash, linked_hash);
                linked_hash = _calculate_hash_for_triples_linked_by_object(graph, s);
                graph_hash = _modulo_hash(graph_hash, linked_hash);
            }
            
            if(_is_bnode(o)){
                linked_hash = _calculate_hash_for_triples_linked_by_object(graph, o);
                graph_hash = _modulo_hash(graph_hash, linked_hash);
                linked_hash = _calculate_hash_for_triples_linked_by_subject(graph, o);
                graph_hash = _modulo_hash(graph_hash, linked_hash);
            }
            
        }
        return  uint2hexstr(graph_hash);
    }
    
    function _calculate_triple_hash(
        bytes memory s, 
        bytes memory p, 
        bytes memory o
    )
        private 
        view 
        returns(uint256 _result)
    {
        string memory encoded_triple = _encode_triple(s,p,o);
        bytes32 triple_hash = sha256(bytes(encoded_triple));
        _result = uint256(triple_hash);
    }
    
    function _calculate_hash_for_triples_linked_by_subject(
        string[3][] memory _graph, 
        bytes memory resource
    ) 
        private 
        view
        returns(uint256 partial_hash)
    {
        partial_hash = 0;

        for(uint256 i = 0; i < _graph.length; i++){
            if(keccak256(resource) == keccak256(bytes(_graph[i][2]))){
                partial_hash = _modulo_hash(partial_hash, _calculate_triple_hash(bytes(_graph[i][0]), bytes(_graph[i][1]), bytes(_graph[i][2])));
            }
        }
    }
    
  
    function _calculate_hash_for_triples_linked_by_object(
        string[3][] memory _graph, 
        bytes memory resource
    ) 
        private 
        view
        returns(uint256 partial_hash)
    {
        partial_hash = 0;
        for(uint256 i = 0; i < _graph.length; i++){
            if(keccak256(resource) == keccak256(bytes(_graph[i][0]))){
                partial_hash = _modulo_hash(partial_hash, _calculate_triple_hash(bytes(_graph[i][0]), bytes(_graph[i][1]), bytes(_graph[i][2])));
            }
        }
    }
    
    function _encode_triple(
        bytes memory s, 
        bytes memory p, 
        bytes memory o
    ) 
        private 
        view 
        returns(string memory _str) 
    {
        bytes memory s_encoded;
        // string memory p_encoded;
        bytes memory o_encoded;
        // string memory _str;

        if(_is_bnode(s)){
            s_encoded = _BLANK_NODE_SUBJECT_NAME;
        } 
        else {
            s_encoded = s;
        }

        // p_encoded = p;

        if(_is_bnode(o)){
            o_encoded = _BLANK_NODE_OBJECT_NAME;
        }
        else {
            o_encoded = o;
        }

        _str = string(abi.encodePacked(s_encoded, p, o_encoded));
        // return _str;
    }
    
    function _modulo_hash(uint256 _a_number, uint256 _a_hash) private pure returns(uint256 _result) {
        assembly{
            _result:=add(_a_number,_a_hash)
        }
    }
  
    function _is_bnode(bytes memory _resource) private pure returns(bool) {
        // if(keccak256(bytes(_resource)) == keccak256(bytes(""))) return true;
        // return false;
        if(_resource[0] == "_" && _resource[1] == ":") return true;
        else return false;
    }
    
    function uint2hexstr(uint i) private pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(87 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }

}