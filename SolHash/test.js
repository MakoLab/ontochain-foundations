
const IHash = artifacts.require("IHash")
const fs = require('fs')
const rdf = require('rdf-ext')
const N3Parser = require('rdf-parser-n3')
const IHashJs = require('./IHash')

module.exports = async function(callback) {

    try{
      const fileReges = /\.n3$/;
      var path_to_file;
      process.argv.forEach(function(val, index, array){
        if(fileReges.test(val)){
          path_to_file = process.argv[index];
        }
      })
      if(fs.existsSync(path_to_file)){

        const parser = new N3Parser({factory: rdf})
        const quadStream = parser.import(fs.createReadStream(path_to_file))
        const dataset = await rdf.dataset().import(quadStream)
        var hashJs = IHashJs(dataset);

        const str = fs.readFileSync(path_to_file).toString();
        const iHash = await IHash.deployed()
        var result = await iHash.calculate_hash_string(str);
        console.log(hashJs +"\t"+result);
      }
      else {
        console.log("File " + path_to_file + " not found");
      }

        // process.argv.forEach(function(val, index, array){
        //   if(val === '-graph'){
        //     path_to_file = process.argv[index+1];
        //   }
        // })

       

    }
    catch(error){
        console.log(error)
    }

    callback()
  }
