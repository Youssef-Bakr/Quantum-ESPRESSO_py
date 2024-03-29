import qepy
import unittest
import pathlib
import shutil
try:
    from mpi4py import MPI
    comm = MPI.COMM_WORLD
    commf = comm.py2f()
except Exception:
    comm = None
    commf = None

class Test(unittest.TestCase):
    def test_pw_comm(self):
        # return # Take some time to finish
        path = pathlib.Path(__file__).resolve().parent / 'DATA'
        fname = path / 'qe_fake.in'
        for i in range(1000): # Error happened ~450
            qepy.qepy_pwscf(fname, commf)
            # qepy.qepy_mod.qepy_set_stdout('/dev/null')
            qepy.qepy_mod.qepy_set_stdout('al.out')
            qepy.qepy_stop_run(0, what = 'no')
            qepy.qepy_mod.qepy_write_stdout(f'Test step = {i}')
            print('istep = ', i, flush = True)

    def test_initial_comm(self):
        return # read_file take some time
        inputobj = qepy.qepy_common.input_base()
        inputobj.prefix = 'al'
        if commf : inputobj.my_world_comm = commf
        for i in range(50000): # Error happened ~16000
            # qepy.qepy_mod.qepy_set_stdout('/dev/null')
            qepy.qepy_mod.qepy_set_stdout('al.out')
            qepy.qepy_initial(inputobj)
            # qepy.read_file()
            qepy.qepy_stop_run(0, what = 'no')
            qepy.qepy_mod.qepy_write_stdout(f'Test step = {i}')

    def tearDown(self):
        if comm and comm.rank == 0 :
            path = pathlib.Path('.')
            for f in path.glob('al.*'):
                if f.is_file():
                    f.unlink()
                else :
                    shutil.rmtree(f)


if __name__ == "__main__":
    unittest.main()
