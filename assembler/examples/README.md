# Examples

## Development Tips

Compile assembly into machine code with:

```sh
make
```

(requires RISC-V tool chain, ideally on Linux or WSL)

Send 32-bit instructions to FPGA over USB with:

```sh
make upload
```

> [!NOTE]
> Make sure port is available at `/dev/ttyUSB1` or change path in
> [uploader.py](./uploader.py).
>
> If the port is accessible through windows (but not WSL, as the tool chain
> requires) run
>
> ```sh
> usbipd attach --busid 1-1 --wsl # in windows land
>
> # if things are still not visible in /dev/ttyUSB then run this:
> sudo modprobe ftdi_sio # in WSL land
> ```
>
> or something similar to allow the port to exist in WSL land instead. Requires
> installation of `usbipd` package, available with `winget`.
