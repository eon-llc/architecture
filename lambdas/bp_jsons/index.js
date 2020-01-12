const axios = require('axios');

exports.handler = (event, context, callback) => {

    async function fetch_bp_jsons() {

        let error = {"headers": { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },"statusCode": 500};

        return await axios({
            method: 'post',
            url: 'https://rem.eon.llc/v1/chain/get_table_rows',
            timeout: 5000,
            data: {
                "table":"producers",
                "scope":"rem",
                "code":"rem",
                "limit":1000,
                "json":true
            },
        })
        .then(async (response) => {
            const producers = response.data.rows;//.filter(prod => prod.top21_chosen_time != null_date);
            let bp_jsons = [];
            let promises = [];

            producers.forEach(prod => {
                promises.push(axios.get(prod.url.replace(/\/$/, "") + "/bp.json", {timeout: 5000}).catch(() => { return error; }));
            });

            return await axios.all(promises)
            .then((values) => {
                bp_jsons = values.map(val => {
                    if(val && typeof val.data === 'object' && val.data !== null) {
                        return val.data;
                    }
                });

                return {
                    "headers": { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                    "statusCode": 200,
                    "body": JSON.stringify(bp_jsons)
                };
            })
            .catch(() => { this.set('error', "Failed to fetch bp.json."); });
        })
        .catch(() => { return error; });
    }

    fetch_bp_jsons().then((response) => { callback(null, response); } );
};
