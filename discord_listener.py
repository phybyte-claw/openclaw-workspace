import json
import asyncio
import discord

CREDENTIALS_PATH = '/home/ubuntu/.openclaw/credentials/discord.json'
ROUTING_PATH = '/home/ubuntu/.openclaw/credentials/discord_routing.json'
OPENCLAW_BIN = '/home/ubuntu/.nvm/versions/node/v24.14.1/bin/openclaw'

def load_config(path):
    with open(path, 'r') as f:
        return json.load(f)

try:
    discord_config = load_config(CREDENTIALS_PATH)
    routing_config = load_config(ROUTING_PATH)
except Exception as e:
    print(f"❌ Error loading configs: {e}")
    exit(1)

TOKEN = discord_config['discord_bot_token']
REVERSE_MAP = {int(k): v for k, v in routing_config['discord_routing'].items() if k.isdigit()}

# Per-channel locks — prevents concurrent agent calls colliding on the same session file
CHANNEL_LOCKS = {cid: asyncio.Lock() for cid in REVERSE_MAP}

class ClawDiscordListener(discord.Client):
    async def on_ready(self):
        print(f'⚡ Claw Discord Dispatcher Online as {self.user}')
        for cid, info in REVERSE_MAP.items():
            channel = self.get_channel(cid)
            if channel:
                await channel.send(f"🤖 **{info['name']}** agent online.")

    async def on_message(self, message):
        if message.author == self.user:
            return

        cid = message.channel.id
        if cid not in REVERSE_MAP:
            return

        routing_data = REVERSE_MAP[cid]
        print(f"📩 Incoming [{routing_data['name']}]: '{message.content}'")

        # Use a fixed session ID per channel so the agent keeps context warm,
        # combined with the per-channel lock to prevent concurrent access.
        session_id = f"discord-{routing_data['agent_profile']}"

        task_payload = f"{routing_data['instructions']}\n\nUser message: {message.content}"
        cmd = [
            OPENCLAW_BIN, "agent",
            "--agent", routing_data['agent_profile'],
            "--session-id", session_id,
            "--message", task_payload,
            "--json",
        ]

        async with CHANNEL_LOCKS[cid]:
            try:
                proc = await asyncio.create_subprocess_exec(
                    *cmd,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                )
                stdout, stderr = await proc.communicate()

                if stdout:
                    try:
                        data = json.loads(stdout.decode())
                        res = data["result"]["payloads"][0]["text"].strip()
                    except Exception:
                        res = stdout.decode().strip()

                    print(f"✅ Reply [{routing_data['name']}]: {res[:80]}...")
                    prefix = f"**{routing_data['name'].upper()}**: "
                    chunks = [res[i:i+1900] for i in range(0, len(res), 1900)]
                    await message.channel.send(prefix + chunks[0])
                    for chunk in chunks[1:]:
                        await message.channel.send(chunk)
                else:
                    err = stderr.decode().strip() if stderr else "no output"
                    print(f"⚠️ Agent error [{routing_data['name']}]: {err[:200]}")
                    await message.channel.send(f"⚠️ **Error:** `{err[:200]}`")

            except Exception as e:
                print(f"❌ Dispatcher exception: {e}")
                await message.channel.send(f"❌ **Dispatcher Error:** {str(e)}")

async def main():
    intents = discord.Intents.default()
    intents.message_content = True
    client = ClawDiscordListener(intents=intents)
    await client.start(TOKEN)

if __name__ == '__main__':
    asyncio.run(main())
