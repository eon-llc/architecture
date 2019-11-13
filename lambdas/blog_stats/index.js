const https = require('https');
const xml2js = require('xml2js');
const xmldom = require('xmldom');

let xmlParser = new xml2js.Parser();
let domParser = new xmldom.DOMParser();

exports.handler = (event, context, callback) => {

    function fetch() {
        return new Promise ((resolve, reject) => {

            let options = {
                host: 'medium.com',
                method: 'GET',
                path: '/feed/eon-llc',
                headers: {'user-agent': 'node.js'}
            };

            return https.get(options, (res) => {
                let data = [];

                res.on('data', (chunk) => {
                    data.push(chunk);
                });

                res.on('end', () => {
                    let xmlStringSerialized = domParser.parseFromString(data.join('').replace(/dc:creator/g, "author"), "text/xml");

                    xmlParser.parseStringPromise(xmlStringSerialized).then(function (result) {
                        resolve(result);
                    })
                    .catch(function (err) {
                        reject(err);
                    });
                });

            }).on('error', function(e) {
                reject(e.message);
            });

        });
    }

    async function fetch_stats() {

        let num_repos = 0;
        let num_commits = 0;
        let num_issues = 0;

        return fetch().then( async (feed) => {

            let posts = feed.rss.channel[0].item;
            let latest = posts[0];

            let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
            let date = new Date(latest.pubDate);

            let responseBody = {
                url: latest.link,
                title: latest.title,
                author: latest.author,
                date: months[date.getMonth()] + " " + date.getDay() + ", " + date.getFullYear(),
                total: posts.length,
                tutorials: posts.filter(post => post.category.includes("tutorial")).length
            }

            return {
                "headers": { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                "statusCode": 200,
                "body": JSON.stringify(responseBody)
            };
        });
    }

    fetch_stats().then((response) => { callback(null, response); } );
};