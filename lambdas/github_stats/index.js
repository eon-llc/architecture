const https = require('https');

exports.handler = (event, context, callback) => {

    function fetch(path) {
        return new Promise ((resolve, reject) => {

            let options = {
                host: 'api.github.com',
                path: path,
                method: 'GET',
                headers: {'user-agent': 'node.js'}
            };

            return https.get(options, (res) => {
                let data = [];

                res.on('data', (chunk) => {
                    data.push(chunk);
                });

                res.on('end', () => {
                    resolve(JSON.parse(data.join('')));
                });

            }).on('error', function(e) {
                reject(e.message);
            });

        });
    }

    async function fetch_stats() {

        let num_repos = 0;
        let num_commits = 0;

        await fetch('/orgs/eon-llc/repos').then( async (repos) => {

            num_repos = repos.length;

            for (const repo of repos) {
                // for every repository
                let stats_path = "/repos/" + repo.full_name + "/stats/contributors";

                num_commits += await fetch(stats_path).then((contributors) => {
                    let commits = 0;
                    // for every contributor
                    for(let i=0; i<contributors.length; i++) {
                        commits += contributors[i].total;
                    }
                    return commits;
                });
            }
        });

        let responseBody = {
            num_repos: num_repos,
            num_commits: num_commits
        };

        return {
            "headers": { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            "statusCode": 200,
            "body": JSON.stringify(responseBody)
        };
    }

    fetch_stats().then((response) => { callback(null, response); } );
};
