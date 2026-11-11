import asyncio
import json
import os
import sys
from pathlib import Path
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def main():
    env = dict(os.environ)
    env.update(DISABLE_TELEMETRY='true', BLENDER_MCP_SAFE_MODE='1', BLENDER_HOST='127.0.0.1', BLENDER_PORT='9876')
    params = StdioServerParameters(command=str(Path(sys.executable).with_name('mcp-for-blender.exe')), args=[], env=env)
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            init = await session.initialize()
            tools = await session.list_tools()
            print(json.dumps({'server': init.serverInfo.model_dump(), 'tools': [t.name for t in tools.tools]}))
            if '--scene' in sys.argv:
                status = await session.call_tool('get_addon_status', {})
                print(status.model_dump_json())
                result = await session.call_tool('get_scene_info', {})
                print(result.model_dump_json())

asyncio.run(asyncio.wait_for(main(), timeout=30))
